import YabaiControlCore

func runDefaultConfigsTests(_ t: TestRunner) {
    t.check(!DefaultConfigs.skhdrc.contains("/Users/"), "skhdrc has no machine-specific home path")
    t.check(!DefaultConfigs.skhdrc.contains("move-to-space.sh"), "skhdrc has no external-script reference")
    // 4 focus + 4 swap + 9 space-focus + 9 send-to-space + 3 layout + 3 balance/mirror + 1 restart
    t.check(SkhdParser.bindings(from: DefaultConfigs.skhdrc).count == 33, "skhdrc parses to 33 bindings")
    t.check(!DefaultConfigs.yabairc.contains("load-sa"), "yabairc drops the scripting addition")
    t.check(!DefaultConfigs.yabairc.contains("jq"), "yabairc drops the jq dependency")
    t.check(!DefaultConfigs.yabairc.contains("/Users/"), "yabairc has no machine-specific home path")
}
