import Foundation

/// Portable default skhd/yabai configs, embedded so the app can install a
/// working setup on a machine that has none. Deliberately free of the scripting
/// addition, jq, and machine-specific paths so every line works on a fresh Mac.
public enum DefaultConfigs {
    public static let skhdrc = """
    # ~/.skhdrc — hotkeys for yabai (installed by Yabai Control)
    # Modifier convention: alt = focus/layout, shift+alt = move/send
    # Reload config:  skhd --reload   |   Restart yabai:  shift+alt - r

    # --- focus window (vim-style directions) ---
    alt - h : yabai -m window --focus west
    alt - j : yabai -m window --focus south
    alt - k : yabai -m window --focus north
    alt - l : yabai -m window --focus east

    # --- move/swap window in a direction ---
    shift + alt - h : yabai -m window --swap west  || yabai -m window --warp west
    shift + alt - j : yabai -m window --swap south || yabai -m window --warp south
    shift + alt - k : yabai -m window --swap north || yabai -m window --warp north
    shift + alt - l : yabai -m window --swap east  || yabai -m window --warp east

    # --- focus space 1..9 ---
    alt - 1 : yabai -m space --focus 1
    alt - 2 : yabai -m space --focus 2
    alt - 3 : yabai -m space --focus 3
    alt - 4 : yabai -m space --focus 4
    alt - 5 : yabai -m space --focus 5
    alt - 6 : yabai -m space --focus 6
    alt - 7 : yabai -m space --focus 7
    alt - 8 : yabai -m space --focus 8
    alt - 9 : yabai -m space --focus 9

    # --- send window to space 1..9 AND follow focus ---
    shift + alt - 1 : yabai -m window --space 1 && yabai -m space --focus 1
    shift + alt - 2 : yabai -m window --space 2 && yabai -m space --focus 2
    shift + alt - 3 : yabai -m window --space 3 && yabai -m space --focus 3
    shift + alt - 4 : yabai -m window --space 4 && yabai -m space --focus 4
    shift + alt - 5 : yabai -m window --space 5 && yabai -m space --focus 5
    shift + alt - 6 : yabai -m window --space 6 && yabai -m space --focus 6
    shift + alt - 7 : yabai -m window --space 7 && yabai -m space --focus 7
    shift + alt - 8 : yabai -m window --space 8 && yabai -m space --focus 8
    shift + alt - 9 : yabai -m window --space 9 && yabai -m space --focus 9

    # --- layout / window state ---
    alt - r : yabai -m space --rotate 90
    alt - t : yabai -m window --toggle float --grid 4:4:1:1:2:2
    alt - f : yabai -m window --toggle zoom-fullscreen

    # --- balance / mirror ---
    shift + alt - 0 : yabai -m space --balance
    alt - y : yabai -m space --mirror y-axis
    alt - x : yabai -m space --mirror x-axis

    # --- restart yabai ---
    shift + alt - r : yabai --restart-service
    """

    public static let yabairc = """
    #!/usr/bin/env sh
    # ~/.yabairc — yabai configuration (installed by Yabai Control)

    # Tiling layout (bsp = binary space partitioning).
    yabai -m config layout bsp

    # Gaps & padding
    yabai -m config top_padding    8
    yabai -m config bottom_padding 8
    yabai -m config left_padding   8
    yabai -m config right_padding  8
    yabai -m config window_gap     8

    # New windows spawn to the right/bottom of the focused one
    yabai -m config window_placement second_child

    # Focus follows the window under the mouse (autoraise = also raise it).
    yabai -m config focus_follows_mouse autoraise

    # Float common system/dialog apps so they don't get tiled
    yabai -m rule --add app="^System Settings$"      manage=off
    yabai -m rule --add app="^System Information$"    manage=off
    yabai -m rule --add app="^Archive Utility$"       manage=off
    yabai -m rule --add app="^Calculator$"            manage=off
    yabai -m rule --add title="^(Open|Save)$"         manage=off

    echo "yabai config loaded"
    """
}
