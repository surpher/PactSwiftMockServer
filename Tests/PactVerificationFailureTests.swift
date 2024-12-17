//
//  Created by Marko Justinek on 17/12/2024.
//  Copyright © 2024 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

@testable import PactSwiftMockServer

import XCTest

final class PactVerificationFailureTests: XCTestCase {

	func testFailureTypeInitialization() {
		// Test all failure types
		XCTAssertEqual(PactVerificationFailure.FailureType(rawValue: "missing-request"), .missing)
		XCTAssertEqual(PactVerificationFailure.FailureType(rawValue: "request-not-found"), .requestNotFound)
		XCTAssertEqual(PactVerificationFailure.FailureType(rawValue: "request-mismatch"), .requestMismatch)
		XCTAssertEqual(PactVerificationFailure.FailureType(rawValue: "mock-server-parsing-fail"), .mockServerParsingFail)

		// Test unknown type
		if case .unknown(let value) = PactVerificationFailure.FailureType(rawValue: "unknown-type")! {
			XCTAssertEqual(value, "unknown-type")
		} else {
			XCTFail("Expected unknown type")
		}
	}

	func testFailureTypeRawValue() {
		// Test rawValue conversion for all failure types
		XCTAssertEqual(PactVerificationFailure.FailureType.missing.rawValue, "missing-request")
		XCTAssertEqual(PactVerificationFailure.FailureType.requestNotFound.rawValue, "request-not-found")
		XCTAssertEqual(PactVerificationFailure.FailureType.requestMismatch.rawValue, "request-mismatch")
		XCTAssertEqual(PactVerificationFailure.FailureType.mockServerParsingFail.rawValue, "mock-server-parsing-fail")

		// Test unknown case
		let unknownCase = PactVerificationFailure.FailureType.unknown("custom-error")
		XCTAssertEqual(unknownCase.rawValue, "custom-error")
	}

	func testFailureTypeDescription() {
		// Test description for standard cases
		XCTAssertEqual(PactVerificationFailure.FailureType.missing.description, "Missing request")
		XCTAssertEqual(PactVerificationFailure.FailureType.requestNotFound.description, "Unexpected request")
		XCTAssertEqual(PactVerificationFailure.FailureType.requestMismatch.description, "Request does not match")
		XCTAssertEqual(
			PactVerificationFailure.FailureType.mockServerParsingFail.description,
		"""
		Failed to parse Mock Server error response!
		Please report this as an issue. Provide this test as an example to help us debug and improve this framework.
		""".trimmingCharacters(in: .whitespacesAndNewlines)
		)

		// Test unknown case description
		let unknownCase = PactVerificationFailure.FailureType.unknown("custom-error")
		XCTAssertEqual(
			unknownCase.description,
		"""
		Unknown type custom-error! Not entirely sure what happened!
		Please report this as an issue. Provide this test as an example to help us debug and improve this framework.
		""".trimmingCharacters(in: .whitespacesAndNewlines)
		)
	}


	func testMismatchTypeInitialization() {
		// Test all mismatch types
		XCTAssertEqual(PactVerificationFailure.Mismatch.MismatchType(rawValue: "QueryMismatch"), .query)
		XCTAssertEqual(PactVerificationFailure.Mismatch.MismatchType(rawValue: "BodyTypeMismatch"), .bodyType)
		XCTAssertEqual(PactVerificationFailure.Mismatch.MismatchType(rawValue: "BodyMismatch"), .body)
		XCTAssertEqual(PactVerificationFailure.Mismatch.MismatchType(rawValue: "HeaderMismatch"), .headers)

		// Test unknown type
		if case .unknown(let value) = PactVerificationFailure.Mismatch.MismatchType(rawValue: "CustomMismatch") {
			XCTAssertEqual(value, "CustomMismatch")
		} else {
			XCTFail("Expected unknown type")
		}
	}

	func testDecodingPactVerificationFailure() throws {
		let json = jsonString.data(using: .utf8)!

		let failure = try JSONDecoder().decode(PactVerificationFailure.self, from: json)

		XCTAssertEqual(failure.method, "POST")
		XCTAssertEqual(failure.path, "/api/users")
		XCTAssertEqual(failure.type, .requestMismatch)
		XCTAssertEqual(failure.request?.headers?["Content-Type"], "application/json")
		XCTAssertEqual(failure.mismatches.count, 2)
		XCTAssertEqual(failure.mismatches[0].type, .headers)
		XCTAssertEqual(failure.mismatches[1].type, .body)
	}

	func testFailureDescription() throws {
		let json = jsonString.data(using: .utf8)!
		let failure = try JSONDecoder().decode(PactVerificationFailure.self, from: json)

		// Expected format of the description
		let expectedDescription = """
			Failure: Request does not match "POST /api/users"
			Request:
			  POST /api/users
			  Content-Type: application/json
			--
			HeaderMismatch: Header value does not match
			  Expected: application/json; charset=utf-8
			  Actual: application/json
			  Parameter: Content-Type
			BodyMismatch: Values do not match
			  Expected: { "name": "John" }
			  Actual: { "name": "Jane" }
			  Parameter: body
			"""

		XCTAssertEqual(
			failure.description.trimmingCharacters(in: .whitespacesAndNewlines),
			expectedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
		)
	}

	func testExpectedDecodesIntArrayWhenStringFails() throws {
		// Test data with an integer array
		let json = "[1, 2, 3, 4]".data(using: .utf8)!

		let expected = try JSONDecoder().decode(PactVerificationFailure.Mismatch.Expected.self, from: json)

		// Assert the integer array is correctly decoded
		XCTAssertEqual(expected.expectedIntArray, [1, 2, 3, 4])

		// Assert the string representation is correctly generated
		XCTAssertEqual(expected.expectedString, "1,2,3,4")
	}

	func testActualDecodesIntArrayWhenStringFails() throws {
		// Test data with an integer array
		let json = "[5, 6, 7, 8]".data(using: .utf8)!

		let actual = try JSONDecoder().decode(PactVerificationFailure.Mismatch.Actual.self, from: json)

		// Assert the integer array is correctly decoded
		XCTAssertEqual(actual.actualIntArray, [5, 6, 7, 8])

		// Assert the string representation is correctly generated
		XCTAssertEqual(actual.actualString, "5,6,7,8")
	}


}

// MARK: - Extension

private extension PactVerificationFailureTests {

	var jsonString: String {
	#"""
	{
		"type": "request-mismatch",
		"method": "POST",
		"path": "/api/users",
		"request": {
			"method": "POST",
			"path": "/api/users",
			"headers": {
				"Content-Type": "application/json"
			}
		},
		"mismatches": [
			{
				"type": "HeaderMismatch",
				"expected": "application/json; charset=utf-8",
				"actual": "application/json",
				"parameter": "Content-Type",
				"mismatch": "Header value does not match"
			},
			{
				"type": "BodyMismatch",
				"expected": "{ \"name\": \"John\" }",
				"actual": "{ \"name\": \"Jane\" }",
				"parameter": "body",
				"mismatch": "Values do not match"
			}
		]
	}
	"""#
	}
}
