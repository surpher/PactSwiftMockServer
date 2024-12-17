//
//  Created by Oliver Jones on 9/1/2023.
//  Copyright © 2023 Oliver Jones. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

public protocol QueryBuilder {
	/// Configures a query parameter for the Interaction.
	///
	/// Throws the interaction or Pact can't be modified (i.e. the mock server for it has already started)
	/// - Parameters:
	///  - name: The query parameter name.
	///  - values: The query parameter values.
	///
	@discardableResult
	func queryParam(name: String, values: [String]) throws -> Self
}
