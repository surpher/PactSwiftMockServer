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
			name: "PactSwiftMockServer",
			targets: ["PactSwiftMockServer"]
		),

		.library(
			name: "PactSwiftMockServerLinux",
			targets: ["PactSwiftMockServerLinux"]
		)
	],

	dependencies: [
		.package(name: "PactSwiftToolbox", url: "https://github.com/surpher/PactSwiftToolbox.git", from: "0.2.0"),
		.package(name: "PactMockServer", url: "https://github.com/surpher/PactMockServer.git", from: "0.1.0"),
	],

	// MARK: - Targets

	targets: [

		// Vending a XCFramwork binary for Apple's platforms
		.binaryTarget(
			name: "PactSwiftMockServer",
			path: "PactSwiftMockServer.xcframework"
		),

		// Vending the framework for Linux platform
		.target(
			name: "PactSwiftMockServerLinux",
			dependencies: [
				"PactMockServer",
				"PactSwiftToolbox",
			],
			path: "./Sources"
		),

	],

	swiftLanguageVersions: [.v5]

)
