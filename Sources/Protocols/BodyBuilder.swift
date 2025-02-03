//
//  Created by Oliver Jones on 9/1/2023.
//  Copyright © 2023 Oliver Jones. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

public protocol BodyBuilder {

    /// Adds the body for the ``Interaction``.
    ///
    /// For JSON payloads, matching rules can be embedded in the `body`. See
    /// [IntegrationJson.md](https://github.com/pact-foundation/pact-reference/blob/master/rust/pact_ffi/IntegrationJson.md).
    ///
    /// - Throws: ``Interaction/Error/canNotBeModified`` if the interaction or Pact can't be modified (i.e. the mock server for it has already started).
    ///
    /// - Parameters:
    ///   - contentType:
    ///       The content type of the body. Defaults to `text/plain`.
    ///       If `nil`, or can't be parsed, it will set the content type as TEXT.
    ///   - body: The body contents. If `nil` will set the body contents as null.
    ///
    @discardableResult
    func body(_ body: String?, contentType: String) throws -> Self
}
