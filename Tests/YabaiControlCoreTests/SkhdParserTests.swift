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
}
