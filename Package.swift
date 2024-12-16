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
      url: "https://github.com/surpher/PactSwiftMockServerXCFramework/releases/download/vX.Y.Z/PactSwiftMockServer-vX.Y.Z.xcframework.zip",
      checksum: "__foo_bar_baz__"
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
