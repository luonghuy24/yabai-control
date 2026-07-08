let runner = TestRunner()
runner.suite("SkhdParser", runSkhdParserTests)
runner.suite("ConfigInstaller", runConfigInstallerTests)
runner.finish()
