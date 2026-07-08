# Yabai Control

A lightweight macOS menu-bar app for driving [yabai](https://github.com/koekeishiya/yabai)
(the tiling window manager) and [skhd](https://github.com/koekeishiya/skhd) (its hotkey
daemon) from a GUI — no need to memorize commands or hand-edit config files for everyday
tweaks.

It lives in the menu bar as a small icon that also shows your current yabai space index.
Opening it gives you live status, layout controls, and one-click actions.

## Features

- **Live status** — at-a-glance running/stopped indicators for `yabai` and `skhd`, plus the
  focused space index shown next to the menu-bar icon.
- **Layout (current space)** — switch between BSP (tiling), Stack, and Float.
- **Focus behavior** — `focus_follows_mouse` (off / autofocus / autoraise) and a
  `mouse_follows_focus` toggle.
- **Spacing sliders** — window gap and screen padding (0–40 px), applied live.
- **Structure** — new-window placement (first/second child), space actions (balance,
  rotate 90°, mirror X/Y), and focused-window toggles (float, fullscreen/zoom, split
  orientation, sticky).
- **Config inspector** — read out common yabai config values, and a cheat-sheet of your
  `~/.skhdrc` keybindings parsed straight from the file.
- **Config files** — install sensible default `~/.skhdrc` / `~/.yabairc` (existing files
  are backed up with a timestamp first), or open either in your editor.
- **Services** — start / restart / stop yabai and reload skhd from the menu.
- **Start at login** — register/unregister as a login item via `SMAppService`.
- **First-run help** — if yabai/skhd aren't found, offers to install them via Homebrew.

## Requirements

- macOS 13 (Ventura) or later.
- [`yabai`](https://github.com/koekeishiya/yabai) and [`skhd`](https://github.com/koekeishiya/skhd),
  installed via Homebrew. The app auto-detects them under `/opt/homebrew` (Apple Silicon)
  or `/usr/local` (Intel).
- The Swift toolchain (Xcode or the Command Line Tools) to build from source.

```sh
brew install koekeishiya/formulae/yabai koekeishiya/formulae/skhd
```

> **Note:** Some features (creating spaces, and a few config keys) require yabai's
> [scripting addition](https://github.com/koekeishiya/yabai/wiki/Installing-yabai-(latest-release)#configure-scripting-addition),
> which needs partial SIP disabled and a passwordless sudoers entry for `yabai --load-sa`.
> The bundled default `~/.yabairc` includes the relevant lines; they're harmless no-ops
> until that setup is done.

## Build & run

Run straight from source:

```sh
swift build -c release
swift run YabaiControl
```

Or package a proper `.app` bundle (ad-hoc signed, runs as a menu-bar accessory):

```sh
./build.sh            # builds dist/Yabai Control.app
./build.sh --install  # also copies it to /Applications and launches it
```

## Tests

The core parsing/config logic lives in `YabaiControlCore` and is covered by a
framework-free test runner (XCTest / Swift Testing aren't available in a CLT-only
toolchain):

```sh
swift run YabaiControlCoreTests
```

## Project layout

```
Sources/
  YabaiControl/       Menu-bar app (AppKit): status item, menu, actions
  YabaiControlCore/   Reusable core: skhd parser, config installer, bundled defaults
Tests/
  YabaiControlCoreTests/   Framework-free tests for the core
build.sh              Builds and (optionally) installs the .app bundle
```

## License

No license specified yet — all rights reserved by the author unless a `LICENSE` file
is added.
