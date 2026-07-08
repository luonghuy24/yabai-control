import YabaiControlCore

func runDefaultConfigsTests(_ t: TestRunner) {
    t.check(!DefaultConfigs.skhdrc.contains("/Users/harry"), "skhdrc has no machine-specific home path")
    t.check(!DefaultConfigs.skhdrc.contains("move-to-space.sh"), "skhdrc has no external-script reference")
    t.check(SkhdParser.bindings(from: DefaultConfigs.skhdrc).count == 33, "skhdrc parses to 33 bindings")
    t.check(!DefaultConfigs.yabairc.contains("load-sa"), "yabairc drops the scripting addition")
    t.check(!DefaultConfigs.yabairc.contains("jq"), "yabairc drops the jq dependency")
}
