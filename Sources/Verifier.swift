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
@_implementationOnly import PactSwiftToolbox

/// Used to verify the provider side of a pact contract
public final class Verifier {

	public init() {
		// Intentionally left blank
	}

	/// Replays the requests from provided contracts against a provider at provided ``url``
	///
	/// - Parameters:
	///   - options: Verification options
	///
	public func verifyProvider(options: VerificationOptions) -> Result<Bool, ProviderVerificationError> {
		// Run verification command
		Logger.log(message: "VerificationOptions", data: Data(options.args.utf8))
		let verificationResult = pactffi_verify(options.args)

		// Errors are returned as non-zero numeric values
		guard verificationResult == 0 else {
			return .failure(ProviderVerificationError(code: verificationResult))
		}

		// Verification completed successfully
		return .success(true)
	}

}
