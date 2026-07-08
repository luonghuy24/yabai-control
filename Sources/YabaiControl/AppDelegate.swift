import AppKit
import ServiceManagement
import YabaiControlCore

/// A snapshot of the yabai/skhd state the menu renders from. Built off the main
/// thread (each field costs a subprocess call) and cached, so opening the menu
/// never has to spawn a process on the synchronous open path.
struct YabaiState {
    var installed = false
    var yabaiRunning = false
    var skhdRunning = false
    var spaceIndex: Int?
    var spaceLayout = ""
    var focusFollowsMouse = ""
    var mouseFollowsFocus = ""
    var windowGap = 0
    var topPadding = 0
    var windowPlacement = ""
    var bindings: [SkhdBinding] = []
    var loginEnabled = false
}

/// A submenu that rebuilds its contents only when the user actually opens it,
/// keeping expensive work off the parent menu's synchronous open path.
final class LazyMenu: NSMenu, NSMenuDelegate {
    private let populate: (NSMenu) -> Void

    init(title: String, populate: @escaping (NSMenu) -> Void) {
        self.populate = populate
        super.init(title: title)
        self.autoenablesItems = false
        self.delegate = self
    }

    required init(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        populate(menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()

    /// Cached yabai state the menu is built from. Only ever read/written on the main thread.
    private var state = YabaiState()
    /// Serial queue that runs the subprocess-heavy state refresh off the main thread.
    private let refreshQueue = DispatchQueue(label: "com.harry.yabaicontrol.refresh", qos: .userInitiated)

    // Held for the app's lifetime to opt out of App Nap. Without this, macOS throttles
    // this LSUIElement accessory when idle, making each `yabai` subprocess call ~10x slower.
    private var activityToken: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Keep yabai queries responsive when opening the menu"
        )
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "Yabai Control")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageRight
            button.font = NSFont.menuBarFont(ofSize: 0)
            button.toolTip = "Yabai Control"
        }
        menu.autoenablesItems = false
        menu.delegate = self
        statusItem.menu = menu

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeSpaceChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        // One synchronous read at launch (the app isn't throttled yet, so it's fast),
        // then the cache is kept fresh in the background from here on.
        state = AppDelegate.computeState()
        updateWorkspaceIndicator()
        rebuildMenu()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let t0 = DispatchTime.now()
        rebuildMenu()   // instant: built entirely from the cached state
        let ms = Double(DispatchTime.now().uptimeNanoseconds - t0.uptimeNanoseconds) / 1_000_000
        NSLog("YBPERF menuNeedsUpdate(cache) %.2fms", ms)
        refresh()       // freshen the cache in the background for the next open
    }

    @objc private func activeSpaceChanged() {
        refresh()
    }

    // MARK: - State refresh

    /// Reads the full yabai/skhd state. Runs on a background queue — never touches `self`.
    private static func computeState() -> YabaiState {
        var s = YabaiState()
        s.installed = Tools.yabaiInstalled
        s.loginEnabled = (SMAppService.mainApp.status == .enabled)
        guard s.installed else { return s }

        s.yabaiRunning = Yabai.isRunning
        s.skhdRunning = Yabai.skhdRunning
        let space = Yabai.focusedSpaceInfo()
        s.spaceIndex = space.index
        s.spaceLayout = space.layout
        s.focusFollowsMouse = Yabai.config("focus_follows_mouse")
        s.mouseFollowsFocus = Yabai.config("mouse_follows_focus")
        s.windowGap = Int(Double(Yabai.config("window_gap")) ?? 0)
        s.topPadding = Int(Double(Yabai.config("top_padding")) ?? 0)
        s.windowPlacement = Yabai.config("window_placement")
        s.bindings = SkhdParser.bindings()
        return s
    }

    /// Recomputes the cached state off the main thread, then applies it on the main thread.
    private func refresh() {
        refreshQueue.async {
            let fresh = AppDelegate.computeState()
            DispatchQueue.main.async {
                self.state = fresh
                self.updateWorkspaceIndicator()
            }
        }
    }

    /// Shows the focused yabai space index to the left of the menu-bar icon.
    private func updateWorkspaceIndicator() {
        guard let button = statusItem.button else { return }
        if state.installed, state.yabaiRunning, let index = state.spaceIndex {
            button.title = "\(index) "
        } else {
            button.title = ""
        }
    }

    // MARK: - Menu construction (reads only from `state`)

    private func rebuildMenu() {
        menu.removeAllItems()

        guard state.installed else {
            menu.addItem(header("yabai not found"))
            menu.addItem(action("Install yabai + skhd via Homebrew…", #selector(installViaBrew)))
            addQuit()
            return
        }

        menu.addItem(statusLine("yabai", state.yabaiRunning))
        menu.addItem(statusLine("skhd", state.skhdRunning))
        menu.addItem(.separator())

        addLayoutSection()
        menu.addItem(.separator())
        addFocusSection()
        menu.addItem(.separator())
        addSliderSection()
        menu.addItem(.separator())
        addStructureSubmenus()
        menu.addItem(.separator())
        addInfoSubmenus()
        menu.addItem(.separator())
        addServiceSection(yabaiRunning: state.yabaiRunning)
        menu.addItem(.separator())
        addLoginToggle()
        addQuit()
    }

    private func addLayoutSection() {
        menu.addItem(header("Layout — current space"))
        let options = [("BSP (tiling)", "bsp"), ("Stack", "stack"), ("Float", "float")]
        for (title, value) in options {
            menu.addItem(radio(title, checked: state.spaceLayout == value, action: #selector(setLayout(_:)), value: value))
        }
    }

    private func addFocusSection() {
        menu.addItem(header("Focus follows mouse"))
        let options = [("Off", "off"), ("Autofocus", "autofocus"), ("Autoraise", "autoraise")]
        for (title, value) in options {
            menu.addItem(radio(title, checked: state.focusFollowsMouse == value, action: #selector(setFocusFollowsMouse(_:)), value: value))
        }
        menu.addItem(toggle("Mouse follows focus", on: state.mouseFollowsFocus == "on", action: #selector(toggleMouseFollowsFocus)))
    }

    private func addSliderSection() {
        let gapItem = NSMenuItem()
        gapItem.view = SliderMenuItemView(title: "Window gap", minValue: 0, maxValue: 40, value: Double(state.windowGap), format: { "\($0) px" }) { [weak self] value in
            self?.state.windowGap = value
            Yabai.setConfig("window_gap", "\(value)")
        }
        menu.addItem(gapItem)

        let paddingItem = NSMenuItem()
        paddingItem.view = SliderMenuItemView(title: "Screen padding", minValue: 0, maxValue: 40, value: Double(state.topPadding), format: { "\($0) px" }) { [weak self] value in
            self?.state.topPadding = value
            for key in ["top_padding", "bottom_padding", "left_padding", "right_padding"] {
                Yabai.setConfig(key, "\(value)")
            }
        }
        menu.addItem(paddingItem)
    }

    private func addStructureSubmenus() {
        let placementMenu = NSMenu()
        placementMenu.autoenablesItems = false
        placementMenu.addItem(radio("First child", checked: state.windowPlacement == "first_child", action: #selector(setPlacement(_:)), value: "first_child"))
        placementMenu.addItem(radio("Second child", checked: state.windowPlacement == "second_child", action: #selector(setPlacement(_:)), value: "second_child"))
        menu.addItem(submenu("New window placement", placementMenu))

        let spaceMenu = NSMenu()
        spaceMenu.autoenablesItems = false
        spaceMenu.addItem(action("Balance sizes", #selector(spaceBalance)))
        spaceMenu.addItem(action("Rotate 90°", #selector(spaceRotate)))
        spaceMenu.addItem(action("Mirror X-axis", #selector(spaceMirrorX)))
        spaceMenu.addItem(action("Mirror Y-axis", #selector(spaceMirrorY)))
        menu.addItem(submenu("Space actions", spaceMenu))

        let windowMenu = NSMenu()
        windowMenu.autoenablesItems = false
        windowMenu.addItem(action("Toggle float", #selector(windowFloat)))
        windowMenu.addItem(action("Toggle fullscreen (zoom)", #selector(windowZoom)))
        windowMenu.addItem(action("Toggle split orientation", #selector(windowSplit)))
        windowMenu.addItem(action("Toggle sticky", #selector(windowSticky)))
        menu.addItem(submenu("Focused window", windowMenu))
    }

    private func addInfoSubmenus() {
        let keys = [
            "layout", "window_placement", "window_gap", "top_padding",
            "focus_follows_mouse", "mouse_follows_focus", "split_ratio",
            "auto_balance", "window_opacity", "active_window_opacity",
            "window_shadow", "mouse_modifier"
        ]
        // Populated on demand: querying these 12 config values costs ~12 yabai
        // subprocess calls, which we must not run on the synchronous menu-open path.
        let configMenu = LazyMenu(title: "Current config") { [weak self] m in
            for key in keys {
                let value = Yabai.config(key)
                let item = NSMenuItem(title: "\(key) = \(value.isEmpty ? "—" : value)", action: nil, keyEquivalent: "")
                item.isEnabled = false
                m.addItem(item)
            }
            m.addItem(.separator())
            if let self {
                m.addItem(self.action("Open yabai docs (wiki)…", #selector(self.openYabaiDocs)))
            }
        }
        menu.addItem(submenu("Current config", configMenu))

        if !state.bindings.isEmpty {
            let cheatMenu = NSMenu()
            cheatMenu.autoenablesItems = false
            for binding in state.bindings {
                let item = NSMenuItem(title: "\(binding.keys)   →   \(binding.action)", action: nil, keyEquivalent: "")
                item.isEnabled = false
                cheatMenu.addItem(item)
            }
            menu.addItem(submenu("skhd keybindings (\(state.bindings.count))", cheatMenu))
        }

        let filesMenu = NSMenu()
        filesMenu.autoenablesItems = false
        filesMenu.addItem(action("Install default keybindings (~/.skhdrc)", #selector(installDefaultSkhdrc)))
        filesMenu.addItem(action("Install default yabai config (~/.yabairc)", #selector(installDefaultYabairc)))
        filesMenu.addItem(.separator())
        filesMenu.addItem(action("Edit ~/.yabairc", #selector(editYabairc)))
        filesMenu.addItem(action("Edit ~/.skhdrc", #selector(editSkhdrc)))
        menu.addItem(submenu("Config files", filesMenu))
    }

    private func addServiceSection(yabaiRunning: Bool) {
        menu.addItem(action(yabaiRunning ? "Restart yabai" : "Start yabai", #selector(restartYabai)))
        if yabaiRunning {
            menu.addItem(action("Stop yabai", #selector(stopYabai)))
        }
        menu.addItem(action("Reload skhd", #selector(reloadSkhd)))
    }

    private func addLoginToggle() {
        menu.addItem(toggle("Start at login", on: state.loginEnabled, action: #selector(toggleLogin)))
    }

    private func addQuit() {
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Yabai Control", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    // MARK: - Item builders

    private func header(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.attributedTitle = NSAttributedString(
            string: title.uppercased(),
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        return item
    }

    private func statusLine(_ name: String, _ running: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: "\(running ? "●" : "○") \(name): \(running ? "running" : "stopped")", action: nil, keyEquivalent: "")
        item.isEnabled = false
        let color = running ? NSColor.systemGreen : NSColor.systemRed
        item.attributedTitle = NSAttributedString(
            string: item.title,
            attributes: [.foregroundColor: color, .font: NSFont.menuFont(ofSize: 0)]
        )
        return item
    }

    private func radio(_ title: String, checked: Bool, action: Selector, value: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = checked ? .on : .off
        item.representedObject = value
        return item
    }

    private func toggle(_ title: String, on: Bool, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = on ? .on : .off
        return item
    }

    private func action(_ title: String, _ selector: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
        item.target = self
        return item
    }

    private func submenu(_ title: String, _ submenu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    // MARK: - Actions
    //
    // Each mutating action updates the cached field optimistically (so reopening the
    // menu reflects the change instantly) and then kicks a background refresh to reconcile.

    @objc private func setLayout(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String else { return }
        state.spaceLayout = value
        Yabai.setSpaceLayout(value)
        refresh()
    }

    @objc private func setFocusFollowsMouse(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String else { return }
        state.focusFollowsMouse = value
        Yabai.setConfig("focus_follows_mouse", value)
        refresh()
    }

    @objc private func toggleMouseFollowsFocus() {
        let newValue = state.mouseFollowsFocus == "on" ? "off" : "on"
        state.mouseFollowsFocus = newValue
        Yabai.setConfig("mouse_follows_focus", newValue)
        refresh()
    }

    @objc private func setPlacement(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String else { return }
        state.windowPlacement = value
        Yabai.setConfig("window_placement", value)
        refresh()
    }

    @objc private func spaceBalance() { Yabai.message(["space", "--balance"]) }
    @objc private func spaceRotate() { Yabai.message(["space", "--rotate", "90"]) }
    @objc private func spaceMirrorX() { Yabai.message(["space", "--mirror", "x-axis"]) }
    @objc private func spaceMirrorY() { Yabai.message(["space", "--mirror", "y-axis"]) }

    @objc private func windowFloat() { Yabai.message(["window", "--toggle", "float"]) }
    @objc private func windowZoom() { Yabai.message(["window", "--toggle", "zoom-fullscreen"]) }
    @objc private func windowSplit() { Yabai.message(["window", "--toggle", "split"]) }
    @objc private func windowSticky() { Yabai.message(["window", "--toggle", "sticky"]) }

    @objc private func installDefaultSkhdrc() {
        installConfig(tool: "skhd", filename: ".skhdrc", contents: DefaultConfigs.skhdrc) {
            _ = Shell.run(Tools.skhd, ["--restart-service"])
        }
    }

    @objc private func installDefaultYabairc() {
        installConfig(tool: "yabai", filename: ".yabairc", contents: DefaultConfigs.yabairc) {
            _ = Shell.run(Tools.yabai, ["--restart-service"])
        }
    }

    /// Writes a bundled default config to ~/<filename>, backing up any existing
    /// file after confirmation, then runs `activate` (restart the relevant
    /// service) and refreshes the cached state so the menu reflects the change.
    private func installConfig(tool: String, filename: String, contents: String, activate: () -> Void) {
        let path = NSHomeDirectory() + "/" + filename

        if ConfigInstaller.exists(at: path) {
            let confirm = NSAlert()
            confirm.messageText = "~/\(filename) already exists"
            confirm.informativeText = "Back it up and replace it with the defaults?"
            confirm.addButton(withTitle: "Back up & Replace")
            confirm.addButton(withTitle: "Cancel")
            NSApp.activate(ignoringOtherApps: true)
            guard confirm.runModal() == .alertFirstButtonReturn else { return }
        }

        do {
            let backup = try ConfigInstaller.write(contents, to: path, timestamp: Self.backupTimestamp())
            activate()
            refresh()

            let done = NSAlert()
            done.messageText = "Installed ~/\(filename)"
            var notes: [String] = []
            if let backup { notes.append("Your previous file was backed up to:\n\(backup)") }
            notes.append("On first launch macOS may ask you to grant Accessibility permission to \(tool).")
            done.informativeText = notes.joined(separator: "\n\n")
            done.addButton(withTitle: "OK")
            NSApp.activate(ignoringOtherApps: true)
            done.runModal()
        } catch {
            let failure = NSAlert()
            failure.messageText = "Could not install ~/\(filename)"
            failure.informativeText = error.localizedDescription
            failure.addButton(withTitle: "OK")
            NSApp.activate(ignoringOtherApps: true)
            failure.runModal()
        }
    }

    /// Filesystem-safe timestamp for backup filenames, e.g. "20260708-142530".
    private static func backupTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    @objc private func editYabairc() { openInEditor(NSHomeDirectory() + "/.yabairc") }
    @objc private func editSkhdrc() { openInEditor(NSHomeDirectory() + "/.skhdrc") }

    @objc private func openYabaiDocs() {
        if let url = URL(string: "https://github.com/koekeishiya/yabai/wiki/Configuration") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func restartYabai() {
        state.yabaiRunning = true
        _ = Shell.run(Tools.yabai, ["--restart-service"])
        refresh()
    }

    @objc private func stopYabai() {
        state.yabaiRunning = false
        _ = Shell.run(Tools.yabai, ["--stop-service"])
        refresh()
    }

    @objc private func reloadSkhd() {
        _ = Shell.run(Tools.skhd, ["--reload"])
        refresh()
    }

    @objc private func installViaBrew() {
        let script = "tell application \"Terminal\" to do script \"brew install koekeishiya/formulae/yabai koekeishiya/formulae/skhd\""
        _ = Shell.run("/usr/bin/osascript", ["-e", script])
    }

    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: - Helpers

    private func openInEditor(_ path: String) {
        _ = Shell.run("/usr/bin/open", ["-t", path])
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                state.loginEnabled = false
            } else {
                try SMAppService.mainApp.register()
                state.loginEnabled = true
            }
        } catch {
            NSLog("Yabai Control: login item toggle failed: \(error)")
        }
        refresh()
    }
}
