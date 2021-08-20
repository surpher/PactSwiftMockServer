//
//  Created by Marko Justinek on 19/8/21.
//  Copyright © 2021 Marko Justinek. All rights reserved.
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

/* TODO:

  1. Should it be set up as `Either<SimpleAuth, Token>`? Using this approach there wouldn't be any optionals here.

*/

import Foundation

public struct PactBroker {

	/// The URL of Pact Broker for broker-based verification
	let url: String

	/// Username when authenticating with a Pact Broker
	public let username: String

	/// Password when authenticating with a Pact Broker
	public let password: String

	/// Token is required when authenticating using the Bearer token mechanism
	public let token: String

	/// Whether to publish the verification results to the Pact Broker
	public let publishVerificationResult: Bool

}
