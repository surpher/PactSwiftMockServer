//
//  Created by Oliver Jones on 12/12/2022.
//  Copyright © 2022 Oliver Jones. All rights reserved.
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

public final class Pact {
    
    public enum Specification {
        case v1, v1_1, v2, v3, v4
    }
    
    public enum Error {
        case canNotBeModified
        
        /// The Pact file could not be written.  The associated error codes:
        ///
        /// - 1 - The function panicked.
        /// - 2 - The pact file was not able to be written.
        /// - 3 - The pact for the given handle was not found.
        case canNotWritePact(Int32)
    }
    
    public enum LogLevel: String {
        case trace = "TRACE", debug = "DEBUG", info = "INFO", warn = "WARN", error = "ERROR"
    }
    
    public static var version: String {
        String(cString: pactffi_version())
    }
    
    static private(set) var isInitialized: Bool = false
    
    static func initalize(logLevel: LogLevel = .warn) {
        if isInitialized == false {
            pactffi_init_with_log_level(logLevel.rawValue.cString(using: .utf8))
            isInitialized = true
        }
    }
    
    public let consumer: String
    public let provider: String
    
    internal let handle: PactHandle
    
    public var filename: String {
        "\(consumer)-\(provider).json"
    }
    
    public init(consumer: String, provider: String) {
        Self.initalize()
        self.consumer = consumer
        self.provider = provider
        self.handle = pactffi_new_pact(consumer.cString(using: .utf8), provider.cString(using: .utf8))
    }
    
    deinit {
        let result = pactffi_free_pact_handle(handle)
        if result > 0 {
            Logger.log(
                message: """
                         Error freeing Pact handle (code: \(result))
                         1 - The handle is not valid or does not refer to a valid Pact. Could be that it was previously deleted.
                         """
            )
        }
    }
    
    /// Sets the specification version for a given Pact model.
    ///
    /// Throws ``Error/canNotBeModified`` if Pact can’t be modified (i.e. the mock server for it has already started).
    public func withSpecification(_ specification: Specification) throws -> Self {
        guard pactffi_with_specification(handle, PactSpecification(specification)) else {
            throw Error.canNotBeModified
        }
        
        return self
    }
    
    /// Sets the additional metadata on the Pact file.
    ///
    /// Common uses are to add the client library details such as the name and version.
    ///
    /// - Throws: ``Error/canNotBeModified`` if Pact can’t be modified (i.e. the mock server for it has already started).
    /// - Parameters:
    ///   - namespace: The top level metadata key to set any key values on.
    ///   - name: The key to set
    ///   - value: The value to set
    public func withMetadata(namespace: String, name: String, value: String) throws -> Self {
        guard pactffi_with_pact_metadata(handle, namespace.cString(using: .utf8), name.cString(using: .utf8), value.cString(using: .utf8)) else {
            throw Error.canNotBeModified
        }
        return self
    }
        
    /// Create a new `Interaction`.
    ///
    /// - parameter description - The interaction description. It needs to be unique for each interaction.
    internal func uponReceiving(_ description: String) -> Interaction {
        Interaction(pactHandle: handle, description: description)
    }
    
    /// Write out the pact file.
    ///
    /// This function should be called if all the consumer tests have passed.
    ///
    /// - Parameters:
    ///   - directory: The directory to write the file to. When `nil` the current working directory is used.
    ///   - overwrite: When `true`, the file will be overwritten with the contents of the current pact. Otherwise, it will be merged with any existing pact file.
    ///
    public func writePactFile(directory: String? = nil, overwrite: Bool = false) throws {
        let writeDirectory = directory ?? FileManager.default.currentDirectoryPath
        Logger.log(message: "Attempting to write pact to file in directory '\(writeDirectory)'")
        let result = pactffi_pact_handle_write_file(handle, writeDirectory.cString(using: .utf8), overwrite)
        guard result == 0 else {
            throw Error.canNotWritePact(result)
        }
        
        Logger.log(message: "Wrote pact to '\(writeDirectory)/\(filename)'")
    }
    
}

extension Pact.Error: LocalizedError {
    public var failureReason: String? {
        switch self {
        case .canNotBeModified:
            return NSLocalizedString("Pact can not be modified", comment: "A error failure reason when a Pact can not be modified")
        case .canNotWritePact(let code):
            return String.localizedStringWithFormat(NSLocalizedString("Can not write to Pact file (error code: %d)", comment: "Format for error failure reason when can't write to Pact file"), code)
        }
    }
}

private extension PactSpecification {
    init(_ specification: Pact.Specification) {
        switch specification {
        case .v1: self = PactSpecification_V1
        case .v1_1: self = PactSpecification_V1_1
        case .v2: self = PactSpecification_V2
        case .v3: self = PactSpecification_V3
        case .v4: self = PactSpecification_V4
        }
    }
    
}

