// swift-tools-version:5.9
import PackageDescription

let package = Package(

  name: "PactSwiftMockServer",

  platforms: [
    .linux
  ],

  products: [
    .library(
      name: "PactSwiftMockServerLinux",
      targets: ["PactSwiftMockServerLinux"]
    ),
  ],

  dependencies: [
  ],

  // MARK: - Targets

  targets: [
    // Using XCFramework zip archive for Apple platforms...
    // Use the following in PactSwift > Package.swift
    // .binaryTarget(
    //   name: "PactSwiftMockServer",
    //   url: "https://github.com/surpher/PactSwiftMockServerXCFramework/releases/download/<___RELEASE_TAG___>/PactSwiftMockServer-<___RELEASE_TAG___>.xcframework.zip",
    //   checksum: "<___CHECKSUM___>"
    // ),

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
