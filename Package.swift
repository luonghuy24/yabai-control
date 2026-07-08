// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "YabaiControl",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "YabaiControlCore",
            path: "Sources/YabaiControlCore"
        ),
        .executableTarget(
            name: "YabaiControl",
            dependencies: ["YabaiControlCore"],
            path: "Sources/YabaiControl"
        ),
        // Framework-free test runner (XCTest/Swift Testing unavailable in CLT-only toolchain).
        // Run with: swift run YabaiControlCoreTests
        .executableTarget(
            name: "YabaiControlCoreTests",
            dependencies: ["YabaiControlCore"],
            path: "Tests/YabaiControlCoreTests"
        )
    ]
)
