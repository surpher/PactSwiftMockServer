//
//  Created by Oliver Jones on 12/12/2022.
//  Copyright © 2022 Oliver Jones. All rights reserved.
//
//  See LICENSE file for licensing information.
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

    // MARK: - Interaction

    /// HTTP Method for an ``Interaction``.
    public enum HTTPMethod: String {
        case GET, HEAD, POST, PUT, PATCH, DELETE, TRACE, CONNECT, OPTIONS
    }

    private let handle: InteractionHandle
    private let ffiProvider: PactFFIProviding

    internal init(pactHandle: PactHandle, description: String, ffiProvider: PactFFIProviding = DefaultPactFFIProvider()) {
        self.ffiProvider = ffiProvider
        self.handle = ffiProvider.newInteraction(handle: pactHandle, description: description)
    }

    /// Adds a provider state to the Interaction.
    ///
    /// Throws ``Interaction/Error/canNotBeModified`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started)
    ///
    /// - Parameters:
    ///   - description - The provider state description.
    ///
    /// - Important: `description` must be unique across all interactions in one Pact contract!
    ///
    @discardableResult
    internal func given(_ description: String) throws -> Self {
        try ffiProvider.given(handle: handle, description: description)

        return self
    }

    /// Sets the test name annotation for the interaction.
    ///
    /// Allows capturing the name of the test as metadata.
    ///
    /// - Parameters:
    ///   - name: Name of the annotation.
    ///
    /// - Warning: This can only be used with `PactSpecification.v4` interactions.
    ///
    /// - Throws: ``Interaction/Error`` if the interaction or pact can't be modified.
    ///
    @discardableResult
    public func testName(_ name: String) throws -> Self {
        precondition(name.isEmpty == false, "The test name must not be empty!")
        try ffiProvider.interactionTestName(handle: handle, name: name)

        return self
    }

    /// Adds a provider state to the Interaction with a parameter key and value.
    ///
    /// - Parameters:
    ///   - description - The provider state description. It needs to be unique.
    ///   - name - Parameter name.
    ///   - value - Parameter value.
    ///
    /// - Throws: ``Interaction/Error/canNotBeModified`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started)
    ///
    @discardableResult
    internal func given(_ description: String, withName name: String, value: String) throws -> Self {
        try ffiProvider.given(handle: handle, description: description, name: name, value: value)

        return self
    }

    /// Configures the request for the ``Interaction``.
    ///
    /// - Parameters:
    ///   - method: The request method. Defaults to ``HTTPMethod/GET``.
    ///   - path: The request path. Defaults to `"/"`.
    ///   - builder: A ``RequestBuilder`` closure.
    ///
    /// - Throws: ``Interaction/Error/canNotBeModified`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started)
    ///
    @discardableResult
    public func withRequest(method: HTTPMethod = .GET, path: String = "/", builder: RequestBuilder = { _ in }) throws -> Self {
        try ffiProvider.withRequest(handle: handle, method: method, path: path)

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

// MARK: - Extension

public extension Interaction {

    struct ProviderState: Hashable {
        var description: String
        var name: String?
        var value: String?

        /// - Parameters:
        ///   - description - The provider state description. It needs to be unique.
        public init(description: String) {
            self.description = description
        }

        /// - Parameters:
        ///   - description - The provider state description. It needs to be unique.
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
    /// - Parameters:
    ///   - providerStates: A set of unique provider state objects.
    ///
    /// - Throws: ``Error`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started)
    ///
    @discardableResult
    func given(_ providerStates: [ProviderState]) throws -> Self {
        guard Set(providerStates.map(\.description)).count == providerStates.count else {
            throw Error.panic("ProviderState descriptions must be unique!")
        }

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
    /// - Parameters:
    ///   - providerStates: A set of unique provider state objects.
    ///
    /// - Throws: ``Error`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started)
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
                NSLocalizedString("Function panicked (error: %@)", comment: "Error message when a rust function panics"),
                errorMessage ?? ""
            )
        }
    }
}

extension Interaction.ProviderState: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(description: value)
    }
}
