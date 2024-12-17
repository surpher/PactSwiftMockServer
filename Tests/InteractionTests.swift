//
//  Created by Oliver Jones on 16/12/2022.
//  Copyright © 2022 Oliver Jones. All rights reserved.
//
//  See LICENSE file for licensing information.
//

@testable import PactSwiftMockServer

import XCTest

final class InteractionTests: XCTestCase {

	override func setUp() async throws {
		try await super.setUp()
		try await Logging.initialize()
	}

	// MARK: - Tests

	func testInteractionInitialization() throws {
		let pact = try Pact(consumer: "consumer", provider: "provider")
			.withSpecification(.v3)

		try Interaction(pactHandle: pact.handle, description: "An interaction")
			.given("Some provider state")
			.withRequest(method: .GET, path: "/test") { request in
				try request.header("foo", values: ["bar"])
				try request.body(#"{"foo":"bar"}"#, contentType: "application/json")
				try request.queryParam(name: "foo", values: ["bar", "baz"])
			}
			.willRespond(with: TestStatusCode.ok.rawValue) { response in
				try response.header("FOO", values: ["BAR"])
				try response.body(#"hello pact"#, contentType: "text/plain")
			}

		// Nothing to assert as long as it doesn't crash. There is no externally visible state.
	}

	func testInteractionInitializationWithGiven() throws {
		let pact = try Pact(consumer: "consumer", provider: "provider")
			.withSpecification(.v3)

		try Interaction(pactHandle: pact.handle, description: "An interaction")
			.given(
				"Some other provider state",
				withName: #function,
				value: String(describing: #line)
			)
			.withRequest(method: .GET, path: "/test") { request in
				try request.header("foo", values: ["bar"])
				try request.body(#"{"foo":"bar"}"#, contentType: "application/json")
				try request.queryParam(name: "foo", values: ["bar", "baz"])
			}
			.willRespond(with: TestStatusCode.ok.rawValue) { response in
				try response.header("FOO", values: ["BAR"])
				try response.body(#"hello pact"#, contentType: "text/plain")
			}

		// Nothing to assert as long as it doesn't crash. There is no externally visible state.
	}

	// MARK: - ProviderState

	func testProviderStateInitialization() {
		// Test basic initialization
		let state1 = Interaction.ProviderState(description: "test state")
		XCTAssertEqual(state1.description, "test state")
		XCTAssertNil(state1.name)
		XCTAssertNil(state1.value)

		// Test initialization with name and value
		let state2 = Interaction.ProviderState(
			description: "test state with params",
			name: "param1",
			value: "value1"
		)
		XCTAssertEqual(state2.description, "test state with params")
		XCTAssertEqual(state2.name, "param1")
		XCTAssertEqual(state2.value, "value1")
	}

	func testProviderStateHashable() {
		// Create test states
		let state1 = Interaction.ProviderState(description: "state 1")
		let state2 = Interaction.ProviderState(description: "state 1")
		let state3 = Interaction.ProviderState(
			description: "state 1",
			name: "param1",
			value: "value1"
		)
		let state4 = Interaction.ProviderState(
			description: "state 1",
			name: "param1",
			value: "value1"
		)
		let state5 = Interaction.ProviderState(
			description: "state 1",
			name: "param2",
			value: "value1"
		)

		// Test equality
		XCTAssertEqual(state1, state2)
		XCTAssertEqual(state3, state4)
		XCTAssertNotEqual(state1, state3)
		XCTAssertNotEqual(state3, state5)

		// Test hash sets
		let stateSet = Set([state1, state2, state3, state4, state5])
		XCTAssertEqual(stateSet.count, 3)
	}

	func testProviderStateStringLiteralInitialization() {
		let state: Interaction.ProviderState = "test state"
		XCTAssertEqual(state.description, "test state")
		XCTAssertNil(state.name)
		XCTAssertNil(state.value)
	}

	// MARK: - Givens

	func testGivenWithProviderStates() throws {
		let pact = try Pact(consumer: "consumer", provider: "provider")
			.withSpecification(.v4)

		// Test basic provider states without parameters
		try Interaction(pactHandle: pact.handle, description: "Test interaction 1")
			.given(
				Interaction.ProviderState(description: "state 1"),
				Interaction.ProviderState(description: "state 2")
			)

		// Test provider states with parameters
		try Interaction(pactHandle: pact.handle, description: "Test interaction 2")
			.given([
				Interaction.ProviderState(
					description: "state with params 1",
					name: "param1",
					value: "value1"
				),
				Interaction.ProviderState(
					description: "state with params 2",
					name: "param2",
					value: "value2"
				)
			])

		// Test mixed provider states (with and without parameters)
		try Interaction(pactHandle: pact.handle, description: "Test interaction 3")
			.given(
				Interaction.ProviderState(description: "simple state"),
				Interaction.ProviderState(
					description: "complex state",
					name: "param",
					value: "value"
				)
			)

		// Test string literal initialization
		try Interaction(pactHandle: pact.handle, description: "Test interaction 4")
			.given(
				"literal state 1",
				Interaction.ProviderState(
					description: "literal state 2",
					name: "param",
					value: "value"
				)
			)
	}

	func testGivenWithDuplicateProviderStates() throws {
		let pact = try Pact(consumer: "consumer", provider: "provider")
			.withSpecification(.v3)

		// Test that duplicate descriptions trigger precondition failure
		let interaction = Interaction(pactHandle: pact.handle, description: "Test interaction")

		XCTAssertThrowsError(
			try interaction.given([
				Interaction.ProviderState(description: "duplicate state"),
				Interaction.ProviderState(description: "duplicate state")
			])
		)
	}

	func testInteractionErrorFailureReason() {
		// Test canNotBeModified error
		XCTAssertEqual(
			Interaction.Error.canNotBeModified.failureReason,
			"Can not be modified"
		)

		// Test handleInvalid error
		XCTAssertEqual(
			Interaction.Error.handleInvalid.failureReason,
			"Invalid Interaction handle"
		)

		// Test unsupportedForSpecificationVersion error
		XCTAssertEqual(
			Interaction.Error.unsupportedForSpecificationVersion.failureReason,
			"Unsupported for specification version"
		)

		// Test unknownResult error with different codes
		XCTAssertEqual(
			Interaction.Error.unknownResult(42).failureReason,
			"Unknown result (error code: 42)"
		)

		// Test panic error with message
		XCTAssertEqual(
			Interaction.Error.panic("Test error").failureReason,
			"Function panicked (error: Test error)"
		)

		// Test panic error with nil message
		XCTAssertEqual(
			Interaction.Error.panic(nil).failureReason,
			"Function panicked (error: )"
		)
	}
}
