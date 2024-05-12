//
//  Created by Marko Justinek on 18/8/21.
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

import Foundation

#if SWIFT_PACKAGE
import PactMockServer
#endif

public protocol ProviderVerifying {

	/// Triggers the provider verification task
	func verifyProvider(options args: String) -> Result<Bool, ProviderVerificationError>

}

/// Used to verify the provider side of a pact contract
public final class Verifier: ProviderVerifying {

	public init() {
		// Intentionally left blank
	}

	/// Triggers the provider verification task by replaying the requests from provided contracts
	///
	/// - Parameters:
	///   - options: Newline delimited args
	///
	/// See [pact_verifier_cli](https://docs.pact.io/implementation_guides/rust/pact_verifier_cli) for more
	///
	public func verifyProvider(options args: String) -> Result<Bool, ProviderVerificationError> {
		Logger.log(message: "VerificationOptions", data: Data(args.utf8))
		let verificationResult = pactffi_verify(args)

		// Errors are returned as non-zero numeric values
		guard verificationResult == 0 else {
			return .failure(ProviderVerificationError(code: verificationResult))
		}

		// Verification completed successfully
		return .success(true)
	}

}
