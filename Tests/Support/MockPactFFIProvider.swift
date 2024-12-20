//
//  Created by Marko Justinek on 17/12/2024.
//  Copyright © 2024 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

@testable import PactSwiftMockServer

import Foundation

final class MockPactFFIProvider: PactFFIProviding {

    private(set) var _returnNil: Bool = false
    private(set) var specVersion: Pact.Specification = .v3

    func returnNil(_ bool: Bool) {
        _returnNil = bool
    }

    func set(
        returnNil: Bool? = nil,
        specVersion: Pact.Specification? = nil
    ) {
        returnNil.map { self._returnNil = $0 }
        specVersion.map { self.specVersion = $0 }
    }

    // MARK: - Protocol conformance

    enum MockPactFFIProviderError: Error {
        case notImplemented
    }

    var version: String {
        "mock"
    }

    func specVersion(pactHandle: PactHandle) -> Pact.Specification {
        specVersion
    }

    func mockServerForTransferProtocol(pactHandle: PactHandle, socketAddress: String, port: Int32, transferProtocol: PactSwiftMockServer.MockServer.TransferProtocol) throws -> Int32 {
        21_337
    }

    func mockServerMatched(port: Int32) -> Bool {
        false
    }

    func mockServerMismatches(port: Int32) -> String? {
        _returnNil ? nil : Self.mockServerMismatchesString
    }

    func mockServerLogs(port: Int32) -> String? {
        _returnNil ? nil : "mock-server-logs"
    }

    func mockServerCleanup(port: Int32) -> Bool {
        false
    }

    func tlsCACertificate() -> String? {
        _returnNil ? nil : "mock-tls-ca-cert"
    }

    func stringRelease(cert: String) {
        // no-op
    }

    func newPact(consumer: String, provider: String) -> PactHandle {
        PactHandle()
    }

    func freePactHandle(_ handle: PactHandle) -> UInt32 {
        0
    }

    func withSpecification(handle: PactHandle, version: PactSwiftMockServer.Pact.Specification) throws {
        throw MockPactFFIProviderError.notImplemented
    }

    func withMetadata(handle: PactHandle, namespace: String, key: String, value: String) throws {
        throw MockPactFFIProviderError.notImplemented
    }

    func writePactFile(handle: PactHandle, to: String, overwrite: Bool) throws -> Int {
        throw MockPactFFIProviderError.notImplemented
    }

    func newInteraction(handle: PactHandle, description: String) -> InteractionHandle {
        InteractionHandle()
    }

    func interactionTestName(handle: InteractionHandle, name: String) throws {
        throw MockPactFFIProviderError.notImplemented
    }

    func withQueryParameter(handle: InteractionHandle, name: String, values: [String]) throws {
        throw MockPactFFIProviderError.notImplemented
    }

    func withHeader(handle: InteractionHandle, name: String, values: [String], interactionPart: InteractionPart) throws {
        throw MockPactFFIProviderError.notImplemented
    }

    func withBody(handle: InteractionHandle, body: String?, contentType: String?, interactionPart: InteractionPart) throws {
        throw MockPactFFIProviderError.notImplemented
    }

    func withStatus(handle: InteractionHandle, status: Int) throws {
        throw MockPactFFIProviderError.notImplemented
    }

    func given(handle: InteractionHandle, description: String) throws {
        throw MockPactFFIProviderError.notImplemented
    }

    func given(handle: InteractionHandle, description: String, name: String, value: String) throws {
        throw MockPactFFIProviderError.notImplemented
    }

    func withRequest(handle: InteractionHandle, method: PactSwiftMockServer.Interaction.HTTPMethod, path: String) throws {
        throw MockPactFFIProviderError.notImplemented
    }

    func generateString(regex: String) -> String? {
        nil
    }

    func generateDateTimeString(format: String) -> String? {
        nil
    }
}

// MARK: - Private extensions

extension MockPactFFIProvider {

    static var mockServerMismatchesString: String {
        #"""
        [
            {
                "type": "HeaderMismatch",
                "expected": "application/json; charset=utf-8",
                "actual": "application/json",
                "parameter": "Content-Type",
                "mismatch": "Header value does not match"
            },
            {
                "type": "BodyMismatch",
                "expected": "{ \"id\": 1 }",
                "actual": "{ \"id\": \"1\" }",
                "parameter": "body",
                "mismatch": "Type mismatch"
            }
        ]
        """#
    }

}

