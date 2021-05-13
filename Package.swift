// swift-tools-version:5.3

import PackageDescription

let package = Package(

	name: "PactSwiftMockServer",

	platforms: [
		.macOS(.v10_12),
		.iOS(.v12)
	],

	products: [
		.library(
			name: "PactSwiftMockServer",
			targets: ["PactSwiftMockServer"]
		)
	],

	dependencies: [
		.package(url: "https://github.com/surpher/PactMockServer.git", from: "0.0.1-beta"),
		.package(url: "https://github.com/surpher/PactSwiftToolbox.git", from: "0.1.0")
	],

	targets: [
		.binaryTarget(
			name: "PactSwiftMockServer",
			path: "PactSwiftMockServer.xcframework"
		),
	],

	swiftLanguageVersions: [.v5]

)
