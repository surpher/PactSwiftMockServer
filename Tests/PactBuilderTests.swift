//
//  Created by Oliver Jones on 14/12/2022.
//  Copyright © 2022 Oliver Jones. All rights reserved.
//
//  See LICENSE file for licensing information.
//

@testable import PactSwiftMockServer

import XCTest

final class PactBuilderTests: XCTestCase {

	private let consumer = "Test_Consumer"
	private let provider = "Test_Provider"

	var builder: PactBuilder!

	private var pactDirectory: String {
		NSTemporaryDirectory().appending("pacts/")
	}

	override func setUp() async throws {
		try await super.setUp()
		try await Logging.initialize()
	}

	override func setUpWithError() throws {
		try super.setUpWithError()

		guard builder == nil else {
			return
		}

		let pact = try Pact(consumer: consumer, provider: provider)
			.withSpecification(.v4)
			.withMetadata(namespace: "namespace1", name: "name1", value: "value1")
			.withMetadata(namespace: "namespace2", name: "name2", value: "value2")

		let config = PactBuilder.Config(pactDirectory: pactDirectory)
		builder = PactBuilder(pact: pact, config: config)
	}

	func testPactVersion() throws {
		let pact = Pact(consumer: consumer, provider: provider)

		XCTAssertEqual(pact.version, "0.4.23")
	}

	func testGetEvents() async throws {
		try builder
			.uponReceiving("a request to retrieve all events with no authorization")
			.given("There are events")
			.testName(name)
			.withRequest(path: "/events") { request in
				try request.queryParam(name: "something", values: ["orOther"])
			}
			.willRespond(with: TestStatusCode.ok.rawValue) { response in
				try response.body("OK", contentType: "text/plain")
			}

		try await builder.verify { ctx in
			var components = try XCTUnwrap(URLComponents(url: ctx.mockServerURL, resolvingAgainstBaseURL: false))
			components.path = "/events"
			components.queryItems = [
				URLQueryItem(name: "something", value: "orOther"),
			]

			let session = URLSession(configuration: .ephemeral)
			let (data, response) = try await session.data(from: try XCTUnwrap(components.url))

			let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
			XCTAssertEqual(httpResponse.statusCode, TestStatusCode.ok.rawValue)
			XCTAssertEqual(httpResponse.value(forHTTPHeaderField: "Content-Type"), "text/plain")
//			XCTAssertTrue(data.isEmpty) // Responding with "" fails the "text/plain" response header test above
			XCTAssertEqual(data, "OK".data(using: .utf8))
		}
	}

	func testCreateEvent() async throws {
		try builder
			.uponReceiving("a request to create an event with no authorization")
			.given("There are events")
			.testName(name)
			.withRequest(method: .POST, path: "/events") { request in
				try request.header("Accept", values: ["application/json"])
			}
			.willRespond(with: TestStatusCode.accepted.rawValue) { response in
				try response.body("OK", contentType: "text/plain")
			}

		try await builder.verify { ctx in
			var components = try XCTUnwrap(URLComponents(url: ctx.mockServerURL, resolvingAgainstBaseURL: false))
			components.path = "/events"

			var request = URLRequest(url: try XCTUnwrap(components.url))
			request.httpMethod = "POST"
			request.setValue("application/json", forHTTPHeaderField: "Accept")

			let session = URLSession(configuration: .ephemeral)
			let (data, response) = try await session.data(for: request)

			let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
			XCTAssertEqual(httpResponse.statusCode, TestStatusCode.accepted.rawValue)
			XCTAssertEqual(httpResponse.value(forHTTPHeaderField: "Content-Type"), "text/plain")
			XCTAssertEqual(data, "OK".data(using: .utf8))
		}
	}

	func testPactFailureErrorMessage() {
		// Create test verification failures
		let failures = [
			PactVerificationFailure(
				type: .requestMismatch,
				method: "GET",
				path: "/api/test",
				request: .init(method: "GET", path: "/api/test", headers: ["Content-Type": "application/json"]),
				mismatches: [
					.init(
						type: .headers,
						expected: .init(expectedString: "application/json; charset=utf-8", expectedIntArray: []),
						actual: .init(actualString: "application/json", actualIntArray: []),
						parameter: "Content-Type",
						mismatch: "Header value does not match"
					)
				]
			),
			PactVerificationFailure(
				type: .missing,
				method: "POST",
				path: "/api/users",
				request: nil,
				mismatches: []
			)
		]

		let error = PactBuilder.Error.pactFailure(failures)

		// Expected format with multiple failures
		let expectedMessage = """
			Pact Failure (see below):
			Failure: Request does not match "GET /api/test"
			Request:
			  GET /api/test
			  Content-Type: application/json
			--
			HeaderMismatch: Header value does not match
			  Expected: application/json; charset=utf-8
			  Actual: application/json
			  Parameter: Content-Type
			---
			Failure: Missing request "POST /api/users"
			""".trimmingCharacters(in: .whitespacesAndNewlines)

		XCTAssertEqual(
			error.failureReason?.trimmingCharacters(in: .whitespacesAndNewlines),
			expectedMessage
		)
	}

	func testPactFailureWithEmptyFailures() {
		let error = PactBuilder.Error.pactFailure([])

		// Even with empty failures, we should get the basic message
		XCTAssertEqual(
			error.failureReason?.trimmingCharacters(in: .whitespacesAndNewlines),
			"Pact Failure (see below):"
		)
	}

}
