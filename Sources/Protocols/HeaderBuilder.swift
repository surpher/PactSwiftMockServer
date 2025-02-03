//
//  Created by Oliver Jones on 9/1/2023.
//  Copyright © 2023 Oliver Jones. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

public protocol HeaderBuilder {

    /// Configures a header for the Interaction.
    ///
    /// To include matching rules for the header, include the matching rule JSON
    /// format with the value as a single JSON document.
    ///
    /// ```
    /// let value = #"{"value":"2", "pact:matcher:type":"regex", "regex":"\\d+"}"#
    /// builder.header("id", value);
    /// ```
    /// See [IntegrationJson.md](https://github.com/pact-foundation/pact-reference/blob/master/rust/pact_ffi/IntegrationJson.md)
    ///
    /// - Parameters:
    ///   - name: The header name.
    ///   - value: The header values.
    ///
    /// - Throws: ``Interaction/Error/canNotBeModified`` if the interaction or Pact
    /// can't be modified (i.e. the mock server for it has already started).
    @discardableResult
    func header(_ name: String, value: String) throws -> Self

    /// Configures a header for the Interaction with a matcher.
    ///
    /// To include matching rules for the header, include the matching rule JSON
    /// format with the value as a single JSON document.
    ///
    /// ```
    /// let value = #"{"value":"2", "pact:matcher:type":"regex", "regex":"\\d+"}"#
    /// builder.header("id", value);
    /// ```
    /// See [IntegrationJson.md](https://github.com/pact-foundation/pact-reference/blob/master/rust/pact_ffi/IntegrationJson.md)
    ///
    /// - Parameters:
    ///   - name: The header name.
    ///   - value: The header values.
    ///   - matcher: The matcher to use when validating.
    ///
    /// - Throws: ``Interaction/Error/canNotBeModified`` if the interaction or Pact
    /// can't be modified (i.e. the mock server for it has already started).
    @discardableResult
    func header<T: Encodable>(_ name: String, value: String, matcher: PactMatcher<T>) throws -> Self
}

// MARK: - Default implementation

public extension HeaderBuilder {

    @discardableResult
    func header<T: Encodable>(_ name: String, value: String, matcher: PactMatcher<T>) throws -> Self {
        // no-op: default implementation making the method optional
        self
    }
}
