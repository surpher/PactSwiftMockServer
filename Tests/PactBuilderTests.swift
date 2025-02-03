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
        try await Logging.initialize(
            [
                Logging.Sink.Config(.standardOut, filter: .debug),
                Logging.Sink.Config(.standardError, filter: .debug),
            ]
        )
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

    // MARK: - Tests

    func testPactVersion() throws {
        let pact = Pact(consumer: consumer, provider: provider)

        XCTAssertEqual(pact.ffi_version, "0.4.25")
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
//            XCTAssertTrue(data.isEmpty) // Responding with "" fails the "text/plain" response header test above
            XCTAssertEqual(data, "OK".data(using: .utf8))
        }
    }

    func testCreateEvent() async throws {
        try builder
            .uponReceiving("a request to create an event with no authorization")
            .given("There are events")
            .testName(name)
            .withRequest(method: .POST, path: "/events") { request in
                try request.header("Accept", value: "application/json")
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

    // MARK: - Verification errors

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

    // MARK: - Headers

    func testInteractionWithHeaderParameters() async throws {
        let headerParam: (key: String, value: String) = ("foo", "bar")

        try builder
            .uponReceiving("A request for an interaction")
            .given(
                "Some state relying on header parameters",
                withName: #function,
                value: String(describing: #line)
            )
            .withRequest(method: .GET, path: "/interaction") { context in
                try context.header(headerParam.key, value: headerParam.value)
            }
            .willRespond(with: 200)

        try await builder.verify { context in
            let urlRequest = try context.buildURLRequest(path: "/interaction", headers: [headerParam])
            let (_, response) = try await URLSession(configuration: .ephemeral).data(for: urlRequest)

            let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
            XCTAssertEqual(httpResponse.statusCode, 200)
        }
    }

    func testInteractionWithHeaderParametersAndMatchers() async throws {
        // TODO: - Fix this so it can handle an array not just array of one string!
        let headerParam: (key: String, values: [String]) = ("foo", ["bar"])
        let matcher = PactMatcher(
            type: "pact:matcher:type",
            value: "bar",
            regex: #"\[a-zA-Z]+$"#,
            example: "bar"
        )

        try builder
            .uponReceiving("A request for an interaction")
            .given(
                "Some state relying on header parameters",
                withName: #function,
                value: String(describing: #line)
            )
            .withRequest(method: .GET, path: "/interaction") { context in
                try context.header(
                    headerParam.key,
                    value: headerParam.values.joined(separator: ","),
                    matcher: matcher
                )
            }
            .willRespond(with: 200)

        try await builder.verify { context in
            let urlRequest = try context.buildURLRequest(path: "/interaction", headers: [])
            let (_, response) = try await URLSession(configuration: .ephemeral).data(for: urlRequest)

            let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
            XCTAssertEqual(httpResponse.statusCode, 200)
        }
    }

    // MARK: - Query Parameters

    func testInteractionWithQueryParameter() async throws {
        let queryParam: (key: String, values: [String]) = ("item", ["value"])

        try builder
            .uponReceiving("A request for an interaction")
            .given(
                "Some state relying on query parameters",
                withName: #function,
                value: String(describing: #line)
            )
            .withRequest(method: .GET, path: "/interaction") { context in
                try context.queryParam(name: queryParam.key, values: queryParam.values)
            }
            .willRespond(with: 200)

        try await builder.verify { context in
            let url = try context.buildRequestURL(
                path: "/interaction",
                queryItems: [
                    queryParam.key: queryParam.values.joined(separator: ",")
                ]
            )
            let (_, response) = try await URLSession(configuration: .ephemeral).data(from: url)

            let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
            XCTAssertEqual(httpResponse.statusCode, 200)
        }
    }

    func testInteractionWithQueryParameters() async throws {
        let queryParams: [(key: String, values: [String])] = [
            ("foo", ["foo", "bar"]),
            ("bar", ["baz"]),
            ("baz", [])
        ]

        try builder
            .uponReceiving("A request for an interaction")
            .given(
                "Some state relying on query parameters",
                withName: #function,
                value: String(describing: #line)
            )
            .withRequest(method: .GET, path: "/interaction") { context in
                try queryParams.forEach {
                    try context.queryParam(name: $0.key, values: $0.values)
                }
            }
            .willRespond(with: 200)

        try await builder.verify { context in

            let url = try context.buildRequestURL(
                path: "/interaction",
                queryItems: queryParams
                    .shuffled()
                    .compactMap { [$0.key: $0.values.joined(separator: ",")] }
                    .reduce(into: [String: String]()) {
                        $0.merge($1) { (_, new) in new }
                    }
            )
            let (_, response) = try await URLSession(configuration: .ephemeral).data(from: url)

            let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
            XCTAssertEqual(httpResponse.statusCode, 200)
        }
    }

    func testInteractionWithQueryParameterAndMatchers() async throws {
//        let queryParam: (key: String, values: [String]) = ("item", ["value"])
//
//        try builder
//            .uponReceiving("A request for an interaction")
//            .given(
//                "Some state relying on query parameters",
//                withName: #function,
//                value: String(describing: #line)
//            )
//            .withRequest(method: .GET, path: "/interaction") { context in
//                try context.queryParam(name: queryParam.key, values: queryParam.values)
//            }
//            .willRespond(with: 200)
//
//        try await builder.verify { context in
//            let url = try context.buildRequestURL(
//                path: "/interaction",
//                queryItems: [
//                    queryParam.key: queryParam.values.joined(separator: ",")
//                ]
//            )
//            let (data, response) = try await URLSession(configuration: .ephemeral).data(from: url)
//
//            let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
//            print(String(data: data, encoding: .utf8)!)
//            XCTAssertEqual(httpResponse.statusCode, 200)
//        }
    }

    // MARK: - With Body

    func testInteractionWithBody() async throws {
        struct FooBody: Encodable {
            let foo: String
        }

        try builder
            .uponReceiving("A request for an interaction")
            .given(
                "Some state expecting body",
                withName: #function,
                value: String(describing: #line)
            )
            .withRequest(method: .POST, path: "/interaction") { context in
                try context.header("content-type", value: "application/json")
                try context.body(#"{"foo":"bar"}"#, contentType: "application/json")
            }
            .willRespond(with: 200)

        try await builder.verify { context in
            let urlRequest = try context.buildURLRequest(
                path: "/interaction",
                body: FooBody(foo: "bar")
            )
            let (_, response) = try await URLSession(configuration: .ephemeral).data(for: urlRequest)

            let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
            XCTAssertEqual(httpResponse.statusCode, 200)
        }
    }

    func testInteractionWithBinaryBodyInRequest() async throws {
        guard
            let imagePath = Bundle(for: Self.self).path(forResource: "test_image", ofType: "jpg")
        else {
            preconditionFailure("Failed to find path for test image!")
        }

        let fileData = try Data(contentsOf: URL(fileURLWithPath: imagePath))

        try builder
            .uponReceiving("A request for an interaction")
            .given(
                "Some state expecting binary body",
                withName: #function,
                value: String(describing: #line)
            )
            .withRequest(method: .POST, path: "/uploads") { context in
                try context.body(fileData)
            }
            .willRespond(with: 201)

        try await builder.verify { context in
            let urlRequest = try context.buildURLRequest(path: "/uploads", body: fileData)
            let (_, response) = try await URLSession(configuration: .ephemeral).data(for: urlRequest)

            let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
            XCTAssertEqual(httpResponse.statusCode, 201)
        }
    }

    func testInteractionWithBinaryBodyInResponse() async throws {
        guard
            let imagePath = Bundle(for: Self.self).path(forResource: "test_image", ofType: "jpg")
        else {
            preconditionFailure("Failed to find path for test image!")
        }

        let fileData = try Data(contentsOf: URL(fileURLWithPath: imagePath))

        try builder
            .uponReceiving("A request for an interaction")
            .given(
                "Some state expecting binary body",
                withName: #function,
                value: String(describing: #line)
            )
            .withRequest(method: .GET, path: "/uploads/0")
            .willRespond(with: 200) { context in
                try context.body(fileData)
            }

        try await builder.verify { context in
            let url = try context.buildRequestURL(path: "/uploads/0")
            let (responseData, response) = try await URLSession(configuration: .ephemeral).data(from: url)

            let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
            XCTAssertEqual(httpResponse.statusCode, 200)

            XCTAssertEqual(fileData, responseData)
        }
    }
}

// MARK: - Private

private extension PactBuilder.ConsumerContext {

    func buildURLRequest<T: Encodable>(path: String, body: T) throws -> URLRequest {
        var components = try XCTUnwrap(URLComponents(url: mockServerURL, resolvingAgainstBaseURL: false))
        components.path = path

        var request = URLRequest(url: try XCTUnwrap(components.url))
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(body)

        return request
    }

    func buildURLRequest(path: String, body: Data) throws -> URLRequest {
        var components = try XCTUnwrap(URLComponents(url: mockServerURL, resolvingAgainstBaseURL: false))
        components.path = path

        var request = URLRequest(url: try XCTUnwrap(components.url))
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = body

        return request
    }

    func buildURLRequest(path: String, headers: [(String, String)] = []) throws -> URLRequest {
        var components = try XCTUnwrap(URLComponents(url: mockServerURL, resolvingAgainstBaseURL: false))
        components.path = path
        var request = URLRequest(url: try XCTUnwrap(components.url))
        for header in headers {
            request.addValue(header.1, forHTTPHeaderField: header.0)
        }

        return request
    }

    func buildRequestURL(path: String, queryItems: [String: String?] = [:]) throws -> URL {
        var components = try XCTUnwrap(URLComponents(url: mockServerURL, resolvingAgainstBaseURL: false))
        components.path = path
        components.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        return try XCTUnwrap(components.url)
    }
}
