import Testing
import YabaiControlCore

@Suite struct SkhdParserTests {
    @Test func parsesKeysAndSkipsCommentsBlanksAndModes() {
        let content = """
        # a comment

        alt - h : yabai -m window --focus west
        :: default
        """
        let bindings = SkhdParser.bindings(from: content)
        #expect(bindings.count == 1)
        #expect(bindings[0].keys == "alt - h")
        #expect(bindings[0].action == "yabai -m window --focus west")
    }
}
