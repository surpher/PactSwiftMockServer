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
    ///   - value: The header value.
    ///
    /// - Throws: ``Interaction/Error/canNotBeModified`` if the interaction or Pact
    /// can't be modified (i.e. the mock server for it has already started).
    @discardableResult
    func header(_ name: String, value: String) throws -> Self

    /// Configures headers for the Interaction.
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
    ///   - values: The header values.
    ///
    /// - Throws: ``Interaction/Error/canNotBeModified`` if the interaction or Pact
    /// can't be modified (i.e. the mock server for it has already started).
    @discardableResult
    func header(_ name: String, values: [String]) throws -> Self
}
