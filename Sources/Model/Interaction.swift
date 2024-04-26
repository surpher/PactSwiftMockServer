//
//  Created by Oliver Jones on 12/12/2022.
//  Copyright © 2022 Oliver Jones. All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import Foundation

#if SWIFT_PACKAGE
import PactMockServer
#endif

public final class Interaction {

	public enum Error {
		case panic(String?)
		case handleInvalid
		case canNotBeModified
		case unsupportedForSpecificationVersion
		case unknownResult(Int)
	}

	public typealias RequestBuilder = (Request) throws -> Void
	public typealias ResponseBuilder = (Response) throws -> Void

	public struct Request: HeaderBuilder, BodyBuilder, QueryBuilder {
		private let handle: InteractionHandle

		init(handle: InteractionHandle) {
			self.handle = handle
		}

		@discardableResult
		public func queryParam(name: String, values: [String]) throws -> Self {
			for (index, value) in values.enumerated() {
				guard pactffi_with_query_parameter_v2(handle, name.cString(using: .utf8), index, value.cString(using: .utf8)) else {
					throw Error.canNotBeModified
				}
			}

			return self
		}

		@discardableResult
		public func header(_ name: String, values: [String]) throws -> Self {
			for (index, value) in values.enumerated() {
				guard pactffi_with_header_v2(handle, .request, name.cString(using: .utf8), index, value.cString(using: .utf8)) else {
					throw Error.canNotBeModified
				}
			}

			return self
		}

		@discardableResult
		public func body(_ body: String? = nil, contentType: String? = nil) throws -> Self {
			guard pactffi_with_body(handle, .request, (contentType ?? "text/plain").cString(using: .utf8), body?.cString(using: .utf8)) else {
				throw Error.canNotBeModified
			}

			return self
		}
	}

	public struct Response: HeaderBuilder, BodyBuilder {
		private let handle: InteractionHandle

		init(handle: InteractionHandle) {
			self.handle = handle
		}

		/// Configures the response for the Interaction.
		///
		/// Throws if the interaction or Pact can't be modified (i.e. the mock server for it has already started).
		///
		/// - Parameters:
		///   - status - the response status. Defaults to 200.
		///
		@discardableResult
		public func status(_ status: Int) throws -> Self {
			guard pactffi_response_status(handle, UInt16(status)) else {
				throw Error.canNotBeModified
			}

			return self
		}

		@discardableResult
		public func header(_ name: String, values: [String]) throws -> Self {
			for (index, value) in values.enumerated() {
				guard pactffi_with_header_v2(handle, .response, name.cString(using: .utf8), index, value.cString(using: .utf8)) else {
					throw Error.canNotBeModified
				}
			}

			return self
		}

		/// Adds the body for the ``Interaction``.
		///
		/// For JSON payloads, matching rules can be embedded in the `body`. See
		/// [IntegrationJson.md](https://github.com/pact-foundation/pact-reference/blob/master/rust/pact_ffi/IntegrationJson.md).
		///
		/// - Throws: ``Interaction/Error/canNotBeModified`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started).
		/// - Parameters:
		///   - contentType:
		///       The content type of the body. Defaults to `text/plain`. Ignored if a content-type header is already set.
		///       If `nil`, or can't be parsed, it will set the content type as TEXT.
		///   - body: The body contents. If the `body` is `nil` it will set the body contents as null.
		///
		@discardableResult
		public func body(_ body: String? = nil, contentType: String? = nil) throws -> Self {
			guard pactffi_with_body(handle, .response, (contentType ?? "text/plain").cString(using: .utf8), body?.cString(using: .utf8)) else {
				throw Error.canNotBeModified
			}

			return self
		}
	}

	/// HTTP Method for an ``Interaction``.
	public enum HTTPMethod: String {
		case GET, HEAD, POST, PUT, PATCH, DELETE, TRACE, CONNECT, OPTIONS
	}

	private let handle: InteractionHandle

	internal init(pactHandle: PactHandle, description: String) {
		self.handle = pactffi_new_interaction(pactHandle, description.cString(using: .utf8))
	}

	/// Adds a provider state to the Interaction.
	///
	/// Throws ``Error`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started)
	///
	/// - Parameters:
	///   - description - The provider state description. It needs to be unique.
	///
	@discardableResult
	internal func given(_ description: String) throws -> Self {
		guard pactffi_given(handle, description.cString(using: .utf8)) else {
			throw Error.canNotBeModified
		}

		return self
	}

	/// Sets the test name annotation for the interaction. This allows capturing the name of the test as metadata.
	/// - Warning: This can only be used with ``Pact/Specification/v4`` interactions.
	@discardableResult
	public func testName(_ name: String) throws -> Self {
		precondition(name.isEmpty == false, "The test name must not be empty!")

		let result = pactffi_interaction_test_name(handle, name.cString(using: .utf8))
		guard result == 0 else {
			switch result {
			case 1: // Function panicked. Error message will be available by calling `pactffi_get_error_message`.
				throw Error.panic(Logging.lastInternalErrorMessage)
			case 2: // Handle was not valid.
				throw Error.handleInvalid
			case 3: // Mock server was already started and the integration can not be modified.
				throw Error.canNotBeModified
			case 4: // Not a V4 interaction.
				throw Error.unsupportedForSpecificationVersion
			default:
				throw Error.unknownResult(Int(result))
			}
		}

		return self
	}

	/// Adds a provider state to the Interaction with a parameter key and value.
	///
	/// Throws ``Error`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started)
	///
	/// - Parameters:
	///   - description - The provider state description. It needs to be unique.
	///   - name - Parameter name.
	///   - value - Parameter value.
	///
	@discardableResult
	internal func given(_ description: String, withName name: String, value: String) throws -> Self {
		guard pactffi_given_with_param(handle, description.cString(using: .utf8), name.cString(using: .utf8), value.cString(using: .utf8)) else {
			throw Error.canNotBeModified
		}

		return self
	}

	/// Configures the request for the ``Interaction``.
	///
	/// - Throws: ``Error`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started)
	/// - Parameters:
	///   - method: The request method. Defaults to ``HTTPMethod/GET``.
	///   - path: The request path. Defaults to `"/"`.
	///   - builder: A ``RequestBuilder`` closure.
	///
	@discardableResult
	public func withRequest(method: HTTPMethod = .GET, path: String = "/", builder: RequestBuilder = { _ in }) throws -> Self {
		guard pactffi_with_request(handle, method.rawValue.cString(using: .utf8), path.cString(using: .utf8)) else {
			throw Error.canNotBeModified
		}

		let request = Request(handle: handle)
		try builder(request)

		return self
	}

	@discardableResult
	public func willRespond(with status: Int, builder: ResponseBuilder = { _ in }) throws -> Self {
		let response = Response(handle: handle)
		try response.status(status)

		try builder(response)

		return self
	}

}

public extension Interaction {

	struct ProviderState: Hashable {
		var description: String
		var name: String?
		var value: String?

		/// - Parameters:
		///   - description -  The provider state description. It needs to be unique.
		public init(description: String) {
			self.description = description
		}

		/// - Parameters:
		///   - description -  The provider state description. It needs to be unique.
		///   - name - Parameter name.
		///   - value - Parameter value.
		public init(description: String, name: String, value: String) {
			self.description = description
			self.name = name
			self.value = value
		}
	}

	/// Adds `providerStates` to the ``Interaction``.
	///
	/// - Throws: ``Error`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started)
	///
	/// - Parameters:
	///   - description - The provider state description. It needs to be unique.
	///   - name - Parameter name.
	///   - value - Parameter value.
	///
	@discardableResult
	func given(_ providerStates: [ProviderState]) throws -> Self {
		precondition(Set(providerStates.map(\.description)).count == providerStates.count, "ProviderState descriptions must be unique!")

		for state in providerStates {
			if let name = state.name, let value = state.value {
				try given(state.description, withName: name, value: value)
			} else {
				try given(state.description)
			}
		}

		return self
	}

	/// Adds `providerStates` to the ``Interaction``.
	///
	/// Throws ``Error`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started)
	///
	/// - Parameters:
	///   - description - The provider state description. It needs to be unique.
	///   - name - Parameter name.
	///   - value - Parameter value.
	///
	@discardableResult
	func given(_ providerStates: ProviderState...) throws -> Self {
		try given(providerStates)
	}

}

extension Interaction.Error: LocalizedError {
	public var failureReason: String? {
		switch self {
		case .canNotBeModified:
			return NSLocalizedString("Can not be modified", comment: "Error message when the interaction can not be modified")
		case .handleInvalid:
			return NSLocalizedString("Invalid Interaction handle", comment: "Error message when the interaction handle is invalid")
		case .unsupportedForSpecificationVersion:
			return NSLocalizedString(
				"Unsupported for specification version",
				comment: "Error message when the action is not supported by the specification version in use"
			)
		case .unknownResult(let code):
			return String.localizedStringWithFormat(
				NSLocalizedString("Unknown result (error code: %d)", comment: "Error message when an unknown result is returned"),
				code
			)
		case .panic(let errorMessage):
			return String.localizedStringWithFormat(
				NSLocalizedString("Function paniced (error: %@)", comment: "Error message when a rust function panics"),
				errorMessage ?? ""
			)
		}
	}
}

private extension InteractionPart {
	static var request: Self { InteractionPart(rawValue: 0) }
	static var response: Self { InteractionPart(rawValue: 1) }
}

extension Interaction.ProviderState: ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		self.init(description: value)
	}
}
