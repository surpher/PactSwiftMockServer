//
//  Created by Marko Justinek on 17/12/2024.
//  Copyright © 2024 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

protocol PactFFIProviding {

    // Properties

    var version: String { get }

    func specVersion(pactHandle: PactHandle) -> Pact.Specification

    // Mock Server

    func mockServerForTransferProtocol(pactHandle: PactHandle, socketAddress: String, port: Int32, transferProtocol: MockServer.TransferProtocol) throws -> Int32

    func mockServerMatched(port: Int32) -> Bool

    func mockServerMismatches(port: Int32) -> String?

    func mockServerLogs(port: Int32) -> String?

    func mockServerCleanup(port: Int32) -> Bool

    func tlsCACertificate() -> String?

    // Method interface

    func stringRelease(cert: String)

    // Pact

    func newPact(consumer: String, provider: String) -> PactHandle

    @discardableResult
    func freePactHandle(_ handle: PactHandle) -> UInt32

    func withSpecification(handle: PactHandle, version: Pact.Specification) throws

    func withMetadata(handle: PactHandle, namespace: String, key: String, value: String) throws

    @discardableResult
    func writePactFile(handle: PactHandle, to: String, overwrite: Bool) throws -> Int

    // API Interaction

    func newInteraction(handle: PactHandle, description: String) -> InteractionHandle

    func interactionTestName(handle: InteractionHandle, name: String) throws

    func withQueryParameter(handle: InteractionHandle, name: String, value: String) throws

    func withQueryParameterWithoutAssociatedValue(handle: InteractionHandle, name: String) throws

    func withHeader(handle: InteractionHandle, name: String, value: String, interactionPart: InteractionPart) throws

    func withBody(handle: InteractionHandle, body: String?, contentType: String, interactionPart: InteractionPart) throws

    func withStatus(handle: InteractionHandle, status: Int) throws

    func given(handle: InteractionHandle, description: String) throws

    func given(handle: InteractionHandle, description: String, name: String, value: String) throws

    func withRequest(handle: InteractionHandle, method: Interaction.HTTPMethod, path: String) throws

    // Utils

    func generateString(regex: String) -> String?

    func generateDateTimeString(format: String) -> String?

}
