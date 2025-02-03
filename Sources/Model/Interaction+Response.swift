//
//  Created by Marko Justinek on 15/1/2025.
//  Copyright © 2025 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

#if SWIFT_PACKAGE
import PactMockServer
#endif

public extension Interaction {

    struct Response: HeaderBuilder, BodyBuilder {

        private let handle: InteractionHandle
        private let ffiProvider: PactFFIProviding

        init(handle: InteractionHandle, ffiProvider: PactFFIProviding = DefaultPactFFIProvider()) {
            self.handle = handle
            self.ffiProvider = ffiProvider
        }

        /// Configures the response status for the Interaction.
        ///
        /// - Throws: ``Interaction/Error/canNotBeModified`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started).
        ///
        /// - Parameters:
        ///   - status: the response status. Defaults to `200`.
        ///
        @discardableResult
        public func status(_ status: Int) throws -> Self {
            try ffiProvider.withStatus(handle: handle, status: status)

            return self
        }

        /// Configures the response header for the Interaction.
        ///
        /// - Throws: ``Interaction/Error/canNotBeModified`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started).
        ///
        /// - Parameters:
        ///   - name: The name of the header parameter.
        ///   - values: The values for given header.
        ///
        @discardableResult
        public func header(_ name: String, value: String) throws -> Self {
            try ffiProvider.withHeader(handle: handle, name: name, value: value, interactionPart: .response)

            return self
        }

        /// Configures the response body for the ``Interaction``.
        ///
        /// For JSON payloads, matching rules can be embedded in the `body`. See
        /// [IntegrationJson.md](https://github.com/pact-foundation/pact-reference/blob/master/rust/pact_ffi/IntegrationJson.md).
        ///
        /// - Throws: ``Interaction/Error/canNotBeModified`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started).
        /// - Parameters:
        ///   - contentType:
        ///       The content type of the body. Defaults to `text/plain`.
        ///       If `nil`, or can't be parsed, it will set the content type as TEXT.
        ///   - body: The body contents. If the `body` is `nil` it will set the body contents as null.
        ///
        @discardableResult
        public func body(_ body: String? = nil, contentType: String = "text/plain") throws -> Self {
            try ffiProvider.withBody(handle: handle, body: body, contentType: contentType, interactionPart: .response)

            return self
        }
    }
}
