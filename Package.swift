// swift-tools-version:5.7
import PackageDescription

let package = Package(

	name: "PactSwiftMockServer",

	platforms: [
		.macOS(.v13),
		.iOS(.v16),
		.tvOS(.v16)
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
		.package(url: "https://github.com/surpher/PactMockServer.git", exact: "0.1.2"),
	],

	// MARK: - Targets

	targets: [

		// Vending a XCFramework for Apple platforms
		.binaryTarget(
			name: "PactSwiftMockServer",
			path: "PactSwiftMockServer.xcframework"
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
