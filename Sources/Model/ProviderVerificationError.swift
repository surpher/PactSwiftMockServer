//
//  Created by Marko Justinek on 19/8/21.
//  Copyright © 2021 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

/// Errors that can occur during provider verification
public enum ProviderVerificationError: Error, Equatable {

    /// Verification process failed
    case verificationFailed

    /// Null pointer was received
    case nullPointer

    /// Method panicked
    case methodPanicked

    /// Invalid arguments provided to the verification process
    case invalidArguments

    /// Provider verification used in unsupported ways
    case usageError(String)

    /// Unknown error
    case unknown

    /// Defines ProviderVerificationError with the code returned from pactffi_verify()
    init(code: Int32) {
        switch code {
        case 1: self = .verificationFailed
        case 2: self = .nullPointer
        case 3: self = .methodPanicked
        case 4: self = .invalidArguments
        default: self = .unknown
        }
    }

    /// Describes the error
    public var description: String {
        switch self {
        case .verificationFailed: return describing("The verification process failed, see output for errors.")
        case .nullPointer: return describing("A null pointer was received.")
        case .methodPanicked: return describing("The method panicked.")
        case .invalidArguments: return describing("Invalid arguments were provided to the verification process.")
        case .usageError(let message): return describing(message)
        case .unknown: return describing("Unknown error!")
        }
    }
}

private extension ProviderVerificationError {

    /// Prefixes the error description
    func describing(_ message: String) -> String {
        ["Provider Verification Error:", message].joined(separator: " ")
    }
}
