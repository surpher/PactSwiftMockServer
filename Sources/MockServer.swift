//
//  Created by Marko Justinek on 10/5/21.
//  Copyright © 2020 Marko Justinek. All rights reserved.
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

public class MockServer {

    public enum Error: Equatable {
        case unknown(Int32)
        case invalidHandle
        case invalidPactJSON
        case unableToStart
        case panicked
        case invalidAddress
        case tlsConfigFailure
    }
    
	// MARK: - Properties

	/// The URL on which MockServer is running.
    public var baseUrl: URL {
        get {
            var components = URLComponents()
            components.scheme = transferProtocol.protocol
            components.port = Int(port)
            components.host = socketAddress
            
            return components.url!
        }
    }
    
	private let socketAddress = "127.0.0.1"
    private let pact: Pact
    private let transferProtocol: TransferProtocol

	// `port` is a var to support Linux platforms
	public private(set) var port: Int32 = 0
	private var useTLS: Bool {
		transferProtocol == .secure ? true : false
	}
    
	// MARK: - Lifecycle

	/// Creates a MockServer on a random port.
	///
    /// - Throws: ``MockServer/Error`` on error.
	/// - Parameters:
    ///   - pact: The ``Pact`` to create the server with.
    ///   - transferProtocol: The protocol to use when communicating with the mock server; defaults to `.standard`.
    ///   - port: The port on which to run mock server; use `nil` for a random port.
    public init(pact: Pact, transferProtocol: TransferProtocol = .standard, port: Int32? = nil) throws {
        self.transferProtocol = transferProtocol
        self.pact = pact
    
        let tryPort = port ?? Self.randomPort
        Logger.log(message: "Starting mock server on \(socketAddress):\(tryPort)")
        
        let result = pactffi_create_mock_server_for_transport(pact.handle, socketAddress, UInt16(tryPort), useTLS ? "https" : "http", nil)
        if result <= 0 {
            throw Error(rawValue: result)
        }
        
        Logger.log(message: "Mock server started on port \(result)")
        self.port = result
	}

    deinit {
        if port != 0 {
            Logger.log(message: "Shutting down mock server on port \(port)")
            if pactffi_cleanup_mock_server(port) == false {
                Logger.log(message: "Failed to shut down mock server!")
            }
        }
	}

	// MARK: - Interface
    
    /// - Returns: `true` when all expected requests have successfully matched.
    public var requestsMatched: Bool {
        guard port > 0 else {
            return false
        }
        
        return pactffi_mock_server_matched(port)
    }
    
    /// Get a JSON string representing the mismatches following interaction testing.
    public var mismatchesJSON: String? {
        guard port > 0, let cString = pactffi_mock_server_mismatches(port) else {
            return nil
        }
        
        return String(cString: cString)
    }
    
    /// Get a string representing the mock server logs following interaction testing
    ///
    /// - Returns: Log string
    public var logs: String {
        guard port > 0, let cString = pactffi_mock_server_logs(port) else {
            return "ERROR: Unable to retrieve mock server logs"
        }
        
        return String(cString: cString)
    }
}

extension MockServer.Error: LocalizedError {
    public var failureReason: String? {
        switch self {
        case .invalidAddress:
            return NSLocalizedString("Invalid IP address", comment: "Error message when IP address is invalid")
        case .invalidPactJSON:
            return NSLocalizedString("Invalid Pact JSON", comment: "Error message when Pact JSON is invalid")
        case .invalidHandle:
            return NSLocalizedString("Invalid handle when starting mock server", comment: "Error message when handle is invalid")
        case .unableToStart:
            return NSLocalizedString("Unable to start mock server", comment: "Error message when unable to start mock server")
        case .panicked:
            return NSLocalizedString("The Pact reference library panicked", comment: "Error message when the Pact reference library panics")
        case .tlsConfigFailure:
            return NSLocalizedString("Could not create the TLS configuration with the self-signed certificate", comment: "Error message when TLS configuration fails")
        case .unknown(let code):
            return String.localizedStringWithFormat(NSLocalizedString("Unknown mock server error: %d", comment: "Format for unknown error message"), code)
        }
    }
}

extension MockServer.Error: RawRepresentable {
    public init(rawValue: Int32) {
        switch rawValue {
        case -1:
            self = .invalidHandle
        case -2:
            self = .invalidPactJSON
        case -3:
            self = .unableToStart
        case -4:
            self = .panicked
        case -5:
            self = .invalidAddress
        case -6:
            self = .tlsConfigFailure
        default:
            self = .unknown(rawValue)
        }
    }
    
    public var rawValue: Int32 {
        switch self {
        case .unknown(let value):
            return value
        case .invalidHandle:
            return -1
        case .invalidPactJSON:
            return -2
        case .unableToStart:
            return -3
        case .panicked:
            return -4
        case .invalidAddress:
            return -5
        case .tlsConfigFailure:
            return -6
        }
    }
}

// MARK: - Static methods

public extension MockServer {

	/// Generates an example string based on provided regex pattern
	///
	/// Only supports basic regex patterns.
	///
	/// - Parameters:
	///   - regex: The pattern to use
	///
	static nonisolated func generate_value(regex: String) -> String? {
        let result = pactffi_generate_regex_value(regex)
        guard result.tag == StringResult_Ok, let stringPointer = result.ok else {
			return nil
		}
        
		let generatedString = String(cString: stringPointer)
        pactffi_string_delete(stringPointer)

		return generatedString
	}

	/// Generates an example datetime string based on provided format
	///
	/// Returns `nil` if the provided format is invalid
	///
	/// - Parameters:
	///   - format: The format of date to generate
	///
	static nonisolated func generate_date(format: String) -> String? {
        let result = pactffi_generate_datetime_string(format)
        guard result.tag == StringResult_Ok, let stringPointer = result.ok else {
			return nil
		}

		let generatedDatetime = String(cString: stringPointer)
        pactffi_string_delete(stringPointer)

		return generatedDatetime
	}

}

// MARK: - Private

private extension MockServer {

    /// Finds an unsued port on Darwin. Returns ``0`` on Linux.
    static var randomPort: Int32 {
        #if os(Linux)
        return 0
        #else
        // Darwin doesn't seem to use a random available port if ``0`` is sent to pactffi_create_mock_server(_:_:_:)
        return SocketBinder.unusedPort()
        #endif
    }

	/// Descripton of mismatching requests
	var mismatchDescription: String {
		guard let mismatches = mismatchesJSON else {
			return "No response! There might be something fishy going on with your Mock Server..."
		}

		let errorDescription = VerificationErrorHandler(mismatches: mismatches).description
		return errorDescription
	}

}
