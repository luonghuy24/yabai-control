import Foundation

/// Minimal framework-free test harness. XCTest and Swift Testing are unavailable
/// / non-reproducible in this Command-Line-Tools-only toolchain, so tests run as a
/// plain executable: `swift run YabaiControlCoreTests`.
final class TestRunner {
    private var failures = 0

    func check(_ condition: Bool, _ message: String) {
        print(condition ? "  ✓ \(message)" : "  ✗ FAIL: \(message)")
        if !condition { failures += 1 }
    }

    func suite(_ name: String, _ body: (TestRunner) -> Void) {
        print("\(name):")
        body(self)
    }

    func finish() -> Never {
        if failures > 0 {
            print("\n\(failures) check(s) FAILED")
            exit(1)
        }
        print("\nAll checks passed")
        exit(0)
    }
}
