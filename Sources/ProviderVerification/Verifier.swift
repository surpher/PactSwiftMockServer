//
//  Created by Marko Justinek on 18/8/21.
//  Copyright © 2021 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

#if SWIFT_PACKAGE
import PactMockServer
#endif

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
        Logging.log(.debug, message: "VerificationOptions: \(args)")
        let verificationResult = pactffi_verify(args)

        // Errors are returned as non-zero numeric values
        guard verificationResult == 0 else {
            return .failure(ProviderVerificationError(code: verificationResult))
        }

        // Verification completed successfully
        return .success(true)
    }
}
