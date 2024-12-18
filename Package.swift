// swift-tools-version:5.7
import PackageDescription

let package = Package(

  name: "PactSwiftMockServer",

  platforms: [
    .macOS(.v13),
    .iOS(.v16),
    .tvOS(.v16),
  ],

  products: [
    .library(
      name: "PactSwiftMockServer",
      targets: ["PactSwiftMockServer"]
    ),

    .library(
      name: "PactSwiftMockServerLinux",
      targets: ["PactSwiftMockServerLinux"]
    ),
  ],

  dependencies: [

  ],

  // MARK: - Targets

  targets: [

    // Vending a XCFramework for Apple platforms
    .binaryTarget(
      name: "PactSwiftMockServer",
      url: "https://github.com/surpher/PactSwiftMockServerXCFramework/releases/download/v1.0.0/PactSwiftMockServer-v1.0.0.xcframework.zip",
      checksum: "274650326299d5fb582acf8fc2178991a96f420f0d63075e1e3bc906e05a9e02"
    ),

    // Vending source for Linux platform
    .target(
      name: "PactSwiftMockServerLinux",
      dependencies: [
        "PactMockServer",
      ],
      path: "./Sources"
    ),

  ],

  swiftLanguageVersions: [.v5]
)
