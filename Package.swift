// swift-tools-version:5.3

import PackageDescription

let package = Package(

    name: "PactSwiftMockServer",

    platforms: [
        .macOS(.v10_12),
        .iOS(.v12),
        .tvOS(.v12)
    ],

    products: [

        .library(
            name: "PactSwiftMockServerLinux",
            targets: ["PactSwiftMockServerLinux"]
        )
    ],

    dependencies: [
        .package(name: "PactMockServer", url: "https://github.com/surpher/PactMockServer.git", .exact("0.1.2")),
    ],

    // MARK: - Targets

    targets: [

        // PactSwift is configured to use `https://github.com/surpher/PactSwiftServer.git`
        // as a dependency. It must point to a zipped up XCFramework!

        // Vending the framework for Linux platform
        .target(
            name: "PactSwiftMockServerLinux",
            dependencies: [
                "PactMockServer",
            ],
            path: "./Sources"
        ),

        .testTarget(
            name: "PactSwiftMockServerLinuxTests",
            dependencies: [
                "PactSwiftMockServerLinux"
            ],
            path: "./Tests"
        ),
    ],

    swiftLanguageVersions: [.v5]
)
