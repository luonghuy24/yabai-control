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
        .testTarget(
            name: "YabaiControlCoreTests",
            dependencies: ["YabaiControlCore"],
            path: "Tests/YabaiControlCoreTests",
            swiftSettings: [
                .unsafeFlags([
                    "-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks/"
                ])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks/",
                    "-framework", "Testing",
                    "-Xlinker", "-rpath",
                    "-Xlinker", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks/",
                    "-Xlinker", "-rpath",
                    "-Xlinker", "/Library/Developer/CommandLineTools/Library/Developer/usr/lib/"
                ])
            ]
        )
    ]
)
