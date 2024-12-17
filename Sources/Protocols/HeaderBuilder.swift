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
	/// To include matching rules for the header, include the matching rule JSON format with the value as a single JSON document. I.e.
	///
	/// ```
	/// let value = #"{"value":"2", "pact:matcher:type":"regex", "regex":"\\d+"}"#
	/// builder.header("id", [value]);
	/// ```
	/// See [IntegrationJson.md](https://github.com/pact-foundation/pact-reference/blob/master/rust/pact_ffi/IntegrationJson.md)
	///
	/// - Throws: ``Interaction/Error/canNotBeModified`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started).
	/// - Parameters:
	///   - name: The header name.
	///   - value: The header values.
	///
	@discardableResult
	func header(_ name: String, values: [String]) throws -> Self
}
