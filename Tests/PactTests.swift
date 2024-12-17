//
//  Created by Oliver Jones on 16/12/2022.
//  Copyright © 2022 Oliver Jones. All rights reserved.
//
//  See LICENSE file for licensing information.

@testable import PactSwiftMockServer

import XCTest

final class PactTests: XCTestCase {

	func testPactInitialization() throws {
		let pact = try Pact(consumer: "Foo", provider: "Bar")
			.withSpecification(.v4)
			.withMetadata(namespace: "test", name: "name", value: "value")
		
		XCTAssertEqual(pact.consumer, "Foo")
		XCTAssertEqual(pact.provider, "Bar")
		XCTAssertEqual(pact.filename, "Foo-Bar.json")
	}

	func testCanNotBeModifiedError() {
		let error = Pact.Error.canNotBeModified
		XCTAssertEqual(
			error.failureReason,
			"Pact can not be modified"
		)
	}

	func testCanNotWritePactError() {
		// Test various error codes
		let testCases = [
			(1, "Can not write to Pact file (error code: 1)"), // Panic
			(2, "Can not write to Pact file (error code: 2)"), // Write failure
			(3, "Can not write to Pact file (error code: 3)"), // Not found
			(42, "Can not write to Pact file (error code: 42)") // Unknown code
		]

		for (code, expectedMessage) in testCases {
			let error = Pact.Error.canNotWritePact(Int32(code))
			XCTAssertEqual(error.failureReason, expectedMessage)
		}
	}

}
