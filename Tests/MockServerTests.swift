//
//  Created by Marko Justinek on 12/4/2020.
//  Copyright © 2020 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

@testable import PactSwiftMockServer

import XCTest

final class MockServerTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        try await Logging.initialize()
    }

    // MARK: - Tests

    func testMockServer_Initializes() throws {
        let pact = Pact(consumer: "Consumer", provider: "Provider")
        let server = try MockServer(pact: pact, transferProtocol: .standard)
        XCTAssertGreaterThan(server.port, 0)
    }

    func testMockServer_SetsBaseURL() throws {
        let pact = Pact(consumer: "Consumer", provider: "Provider")
        let server = try MockServer(pact: pact, transferProtocol: .standard)
        XCTAssertEqual(server.baseUrl, try XCTUnwrap(URL(string: "http://127.0.0.1:\(server.port)")))
    }

    func testMockServer_SetsBaseSSLURL() throws {
        let pact = Pact(consumer: "Consumer", provider: "Provider")
        let server = try MockServer(pact: pact, transferProtocol: .secure)
        XCTAssertEqual(server.baseUrl, try XCTUnwrap(URL(string: "https://127.0.0.1:\(server.port)")))
    }

    func testMockServer_GetTLSCert() throws {
        let pact = Pact(consumer: "Consumer", provider: "Provider")
        let server = try MockServer(pact: pact, transferProtocol: .secure)
        XCTAssertNotNil(server.tlsCACertificate)
    }

    func testMockServer_NoTLSCert() throws {
        let pact = Pact(consumer: "Consumer", provider: "Provider")
        let mockFFIProvider = MockPactFFIProvider()
        mockFFIProvider.set(returnNil: true)
        let server = try MockServer(pact: pact, transferProtocol: .secure, port: nil, ffiProvider: mockFFIProvider)
        XCTAssertNil(server.tlsCACertificate)
    }

    func testMockServer_Mismatches() throws {
        let pact = Pact(consumer: "Consumer", provider: "Provider")
        let mockFFIProvider = MockPactFFIProvider()
        mockFFIProvider.set(returnNil: false)
        let server = try MockServer(pact: pact, transferProtocol: .secure, port: nil, ffiProvider: mockFFIProvider)
        XCTAssertEqual(server.mismatchesJSON, MockPactFFIProvider.mockServerMismatchesString)
    }

    func testMockServer_NilMismatches() throws {
        let pact = Pact(consumer: "Consumer", provider: "Provider")
        let mockFFIProvider = MockPactFFIProvider()
        mockFFIProvider.set(returnNil: true)
        let server = try MockServer(pact: pact, transferProtocol: .secure, port: nil, ffiProvider: mockFFIProvider)
        XCTAssertNil(server.mismatchesJSON)
    }

    func testMockServer_GetLogs() throws {
        let value = "mock-server-logs"
        let pact = Pact(consumer: "Consumer", provider: "Provider")
        let mockFFIProvider = MockPactFFIProvider()
        mockFFIProvider.set(returnNil: false)
        let server = try MockServer(pact: pact, transferProtocol: .secure, port: nil, ffiProvider: mockFFIProvider)
        XCTAssertEqual(server.logs, value)
    }

    func testMockServer_NoLogs() throws {
        let pact = Pact(consumer: "Consumer", provider: "Provider")
        let mockFFIProvider = MockPactFFIProvider()
        mockFFIProvider.set(returnNil: true)
        let server = try MockServer(pact: pact, transferProtocol: .secure, port: nil, ffiProvider: mockFFIProvider)
        XCTAssertEqual(server.logs, "ERROR: Unable to retrieve mock server logs")
    }
}
