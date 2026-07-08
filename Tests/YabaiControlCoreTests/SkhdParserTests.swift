import YabaiControlCore

func runSkhdParserTests(_ t: TestRunner) {
    let content = """
    # a comment

    alt - h : yabai -m window --focus west
    :: default
    """
    let bindings = SkhdParser.bindings(from: content)
    t.check(bindings.count == 1, "parses 1 binding; skips comment/blank/mode lines")
    t.check(bindings.first?.keys == "alt - h", "keys parsed correctly")
    t.check(bindings.first?.action == "yabai -m window --focus west", "action parsed correctly")

    let colon = SkhdParser.bindings(from: #"alt - a : echo "x : y""#)
    t.check(colon.first?.action == #"echo "x : y""#, "splits on first colon only (colons in action preserved)")

    let long = SkhdParser.bindings(from: "alt - z : " + String(repeating: "x", count: 100))
    t.check(long.first?.action.count == 62, "truncates long actions to 61 chars + ellipsis")
}
