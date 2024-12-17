//
//  Created by Marko Justinek on 25/5/20.
//  Copyright © 2020 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

@testable import PactSwiftMockServer

import XCTest

class MockServerErrorTests: XCTestCase {

	func testErrorCodes() {
		XCTAssertEqual(MockServer.Error.invalidHandle.rawValue, -1)
		XCTAssertEqual(MockServer.Error.invalidPactJSON.rawValue, -2)
		XCTAssertEqual(MockServer.Error.unableToStart.rawValue, -3)
		XCTAssertEqual(MockServer.Error.panicked.rawValue, -4)
		XCTAssertEqual(MockServer.Error.invalidAddress.rawValue, -5)
		XCTAssertEqual(MockServer.Error.tlsConfigFailure.rawValue, -6)
		XCTAssertEqual(MockServer.Error.unknown(-10).rawValue, -10)
	}

	func testRawRepresentable() {
		XCTAssertEqual(MockServer.Error(rawValue: -1), .invalidHandle)
		XCTAssertEqual(MockServer.Error(rawValue: -2), .invalidPactJSON)
		XCTAssertEqual(MockServer.Error(rawValue: -3), .unableToStart)
		XCTAssertEqual(MockServer.Error(rawValue: -4), .panicked)
		XCTAssertEqual(MockServer.Error(rawValue: -5), .invalidAddress)
		XCTAssertEqual(MockServer.Error(rawValue: -6), .tlsConfigFailure)
		XCTAssertEqual(MockServer.Error(rawValue: -10), .unknown(-10))
	}

	func testMockServerErrorFailureReason() {
		// Test all standard error cases
		let testCases: [(MockServer.Error, String)] = [
			(.invalidHandle, "Invalid handle when starting mock server"),
			(.invalidPactJSON, "Invalid Pact JSON"),
			(.unableToStart, "Unable to start mock server"),
			(.panicked, "The Pact reference library panicked"),
			(.invalidAddress, "Invalid IP address"),
			(.tlsConfigFailure, "Could not create the TLS configuration with the self-signed certificate"),
			(.unknown(42), "Unknown mock server error: 42")
		]

		// Test each case
		for (error, expectedMessage) in testCases {
			XCTAssertEqual(error.failureReason, expectedMessage)
		}
	}
}
