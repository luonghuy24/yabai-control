import Foundation

enum Shell {
    @discardableResult
    static func run(_ launchPath: String, _ args: [String]) -> (status: Int32, out: String) {
        guard FileManager.default.isExecutableFile(atPath: launchPath) else { return (-1, "") }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = args
        let outPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = Pipe()
        do {
            try process.run()
        } catch {
            return (-1, "")
        }
        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let text = String(data: data, encoding: .utf8) ?? ""
        return (process.terminationStatus, text.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

enum Tools {
    static let brewPrefix: String = {
        for prefix in ["/opt/homebrew", "/usr/local"] where FileManager.default.isExecutableFile(atPath: "\(prefix)/bin/yabai") {
            return prefix
        }
        return "/opt/homebrew"
    }()

    static var yabai: String { "\(brewPrefix)/bin/yabai" }
    static var skhd: String { "\(brewPrefix)/bin/skhd" }

    static var yabaiInstalled: Bool { FileManager.default.isExecutableFile(atPath: yabai) }
    static var skhdInstalled: Bool { FileManager.default.isExecutableFile(atPath: skhd) }
}

enum Yabai {
    @discardableResult
    static func message(_ args: [String]) -> String {
        Shell.run(Tools.yabai, ["-m"] + args).out
    }

    static func config(_ key: String) -> String {
        Shell.run(Tools.yabai, ["-m", "config", key]).out
    }

    static func setConfig(_ key: String, _ value: String) {
        _ = Shell.run(Tools.yabai, ["-m", "config", key, value])
    }

    /// Index (1-based, global across displays) and layout type of the focused space,
    /// from a single query.
    static func focusedSpaceInfo() -> (index: Int?, layout: String) {
        guard let object = focusedSpace() else { return (nil, "") }
        return (object["index"] as? Int, object["type"] as? String ?? "")
    }

    private static func focusedSpace() -> [String: Any]? {
        let out = Shell.run(Tools.yabai, ["-m", "query", "--spaces", "--space"]).out
        guard let data = out.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return object
    }

    static func setSpaceLayout(_ layout: String) {
        _ = Shell.run(Tools.yabai, ["-m", "space", "--layout", layout])
    }

    static func running(_ name: String) -> Bool {
        let result = Shell.run("/usr/bin/pgrep", ["-x", name])
        return result.status == 0 && !result.out.isEmpty
    }

    static var isRunning: Bool { running("yabai") }
    static var skhdRunning: Bool { running("skhd") }
}
