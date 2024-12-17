//
//  Created by Marko Justinek on 17/12/2024.
//  Copyright © 2024 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

#if SWIFT_PACKAGE
import PactSwiftMockServer
#endif

struct DefaultPactFFIProvider: PactFFIProviding {

	typealias InteractionError = Interaction.Error

	var version: String {
		String(cString: pactffi_version())
	}

	func mockServerForTransferProtocol(
		pactHandle: PactHandle,
		socketAddress: String,
		port: Int32,
		transferProtocol: MockServer.TransferProtocol
	) throws -> Int32 {
		let result = pactffi_create_mock_server_for_transport(
			pactHandle,
			socketAddress,
			UInt16(port),
			transferProtocol.protocol,
			nil
		)
		if result <= 0 {
			throw MockServer.Error(rawValue: result)
		}

		return result
	}

	func mockServerCleanup(port: Int32) -> Bool {
		pactffi_cleanup_mock_server(port)
	}

	func tlsCACertificate() -> String? {
		guard let cString = pactffi_get_tls_ca_certificate() else {
			return nil
		}

		return String(cString: cString)
	}

	func stringRelease(cert: String) {
		pactffi_string_delete(strdup(cert))
	}

	func mockServerMatched(port: Int32) -> Bool {
		pactffi_mock_server_matched(port)
	}

	func mockServerMismatches(port: Int32) -> String? {
		guard let cString = pactffi_mock_server_mismatches(port) else { return nil }
		return String(cString: cString)
	}

	func mockServerLogs(port: Int32) -> String? {
		guard let cString = pactffi_mock_server_logs(port) else { return nil }
		return String(cString: cString)
	}

	func newPact(consumer: String, provider: String) -> PactHandle {
		pactffi_new_pact(consumer.cString(using: .utf8), provider.cString(using: .utf8))
	}

	func freePactHandle(_ handle: PactHandle) -> UInt32 {
		let result = pactffi_free_pact_handle(handle)

		if result > 0 {
			Logging.log(
				.error,
				message: """
						 Error freeing Pact handle (code: \(result))!
						 1 - The handle is not valid or does not refer to a valid Pact. Could be that it was previously deleted.
						"""
					)
				}

		return result
	}

	func withSpecification(handle: PactHandle, version: Pact.Specification) throws {
		guard pactffi_with_specification(handle, PactSpecification(version)) else {
			throw Pact.Error.canNotBeModified
		}
	}

	func withMetadata(handle: PactHandle, namespace: String, key: String, value: String) throws {
		guard pactffi_with_pact_metadata(
			handle,
			namespace.cString(using: .utf8),
			key.cString(using: .utf8),
			value.cString(using: .utf8)
		) else {
			throw Pact.Error.canNotBeModified
		}
	}

	func writePactFile(handle: PactHandle, to writeDirectory: String, overwrite: Bool) throws -> Int {
		let result = pactffi_pact_handle_write_file(
			handle,
			writeDirectory.cString(using: .utf8),
			overwrite
		)
		guard result == 0 else {
			throw Pact.Error.canNotWritePact(result)
		}
		return Int(result)
	}

	// API Interaction

	func newInteraction(handle: PactHandle, description: String) -> InteractionHandle {
		pactffi_new_interaction(handle, description.cString(using: .utf8))
	}

	func withQueryParameter(handle: InteractionHandle, name: String, values: [String]) throws {
		for (index, value) in values.enumerated() {
			guard pactffi_with_query_parameter_v2(
				handle,
				name.cString(using: .utf8),
				index,
				value.cString(using: .utf8)
			) else {
				throw Interaction.Error.canNotBeModified
			}
		}
	}

	func withHeader(handle: InteractionHandle, name: String, values: [String], interactionPart: InteractionPart) throws {
		for (index, value) in values.enumerated() {
			guard pactffi_with_header_v2(
				handle,
				interactionPart,
				name.cString(using: .utf8),
				index,
				value.cString(using: .utf8)
			) else {
				throw Interaction.Error.canNotBeModified
			}
		}
	}

	func withBody(handle: InteractionHandle, body: String?, contentType: String?, interactionPart: InteractionPart) throws {
		guard pactffi_with_body(
			handle,
			interactionPart,
			(contentType ?? "text/plain").cString(using: .utf8),
			body?.cString(using: .utf8)
		) else {
			throw Interaction.Error.canNotBeModified
		}
	}

	func withStatus(handle: InteractionHandle, status: Int) throws {
		guard pactffi_response_status(handle, UInt16(status)) else {
			throw Interaction.Error.canNotBeModified
		}
	}

	func given(handle: InteractionHandle, description: String) throws {
		guard pactffi_given(handle, description.cString(using: .utf8)) else {
			throw Interaction.Error.canNotBeModified
		}
	}

	func interactionTestName(handle: InteractionHandle, name: String) throws {
		let result = pactffi_interaction_test_name(handle, name.cString(using: .utf8))

		guard result == 0 else {
			switch result {
			case 1: // Function panicked. Error message will be available by calling `pactffi_get_error_message`.
				throw InteractionError.panic(Logging.lastInternalErrorMessage)
			case 2: // Handle was not valid.
				throw InteractionError.handleInvalid
			case 3: // Mock server was already started and the integration can not be modified.
				throw InteractionError.canNotBeModified
			case 4: // Not a V4 interaction.
				throw InteractionError.unsupportedForSpecificationVersion
			default:
				throw InteractionError.unknownResult(Int(result))
			}
		}
	}

	func given(handle: InteractionHandle, description: String, name: String, value: String) throws {
		guard pactffi_given_with_param(
			handle,
			description.cString(using: .utf8),
			name.cString(using: .utf8),
			value.cString(using: .utf8)
		) else {
			throw InteractionError.canNotBeModified
		}
	}

	func withRequest(handle: InteractionHandle, method: Interaction.HTTPMethod, path: String) throws {
		guard pactffi_with_request(handle, method.rawValue.cString(using: .utf8), path.cString(using: .utf8)) else {
			throw InteractionError.canNotBeModified
		}
	}
}

// MARK: - Private extensions

private extension PactSpecification {

	init(_ specification: Pact.Specification) {
		switch specification {
		case .v1: self = PactSpecification_V1
		case .v1_1: self = PactSpecification_V1_1
		case .v2: self = PactSpecification_V2
		case .v3: self = PactSpecification_V3
		case .v4: self = PactSpecification_V4
		}
	}
}
