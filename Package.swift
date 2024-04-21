// swift-tools-version:5.7

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
		.package(name: "PactMockServer", url: "https://github.com/surpher/PactMockServer.git", .exact("0.1.2")),
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
			],
			path: "./Sources"
		),

	],

	swiftLanguageVersions: [.v5]

)
