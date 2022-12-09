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

public actor MockServer {

	// MARK: - Properties

	/// The URL on which MockServer is running.
    public var baseUrl: String {
        get async { "\(transferProtocol.protocol)://\(socketAddress):\(port)" }
	}

	private let socketAddress = "127.0.0.1"

	// `port` is a var to support Linux platforms
	private var port: Int32 = 0
	private var tls: Bool {
		transferProtocol == .secure ? true : false
	}

    private let transferProtocol: TransferProtocol
    private let pactDirectory: String
	private let merge: Bool

	// MARK: - Lifecycle

	/// Initializes a MockServer on a random port
	///
	/// - Parameters:
	///   - directory: The directory path to write the Pact contract into; defaults to ``PactFileManager/defaultPactDirectoryPath``.
    ///   - transferProtocol: The protocol to use when communicating with the mock server; defaults to `.standard`.
	///   - merge: Whether to merge interactions with an existing Pact contract.
	///
	public init(
		directory: String? = nil,
        transferProtocol: TransferProtocol = .standard,
		merge: Bool = true
	) {
		self.merge = merge
        self.transferProtocol = transferProtocol
        self.pactDirectory = directory ?? PactFileManager.defaultPactDirectoryPath
	}

    deinit {
        if port != 0 {
            pactffi_cleanup_mock_server(port)
        }
	}

	// MARK: - Interface

	/// Spins up a mock server with expected interactions defined in the provided Pact
	///
	/// - Parameters:
	///   - pact: The pact contract
	///
	public func setup(pact: Data) async throws -> Int {
		Logger.log(message: "Setting up pact mock server for consumer verification", data: pact)
		port = try createMockServer(pact: pact)
				
        return Int(port)
	}

	/// Verifies all interactions passed to mock server
	///
	/// By default pact files are written to `/tmp/pacts`.
	/// Use `PACT_OUTPUT_DIR` environment variable with absolute path to your custom path in schema `run` configuration.
	///
	public func verify() async throws {
        defer { shutdownMockServer() }
		guard requestsMatched else {
            throw VerificationError.reason(mismatchDescription)
		}
	}

	/// Finalises Pact tests by writing the pact contract file to disk
	///
	/// - Parameters:
	///   - pact: The Pact contract to write
	///
	public func finalize(pact: Data) async throws -> String {
		Logger.log(message: "Starting up mock server to finalize writing pact with data:", data: pact)
		let randomPort = Self.randomPort
        
        defer { shutdownMockServer() }
		port = try createMockServer(pact: pact, port: randomPort)

		Logger.log(message: "Mock server started on port \(port). Attempting to write pact file with data:", data: pact)
        return try writePactContractFile(port: port, pactDir: pactDirectory, merge: merge)
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
		guard let stringPointer = pactffi_generate_regex_value(regex).ok._0 else {
			return nil
		}
		let generatedString = String(cString: stringPointer)
		pactffi_free_string(stringPointer)

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
		guard let stringPointer = pactffi_generate_datetime_string(format).ok._0 else {
			return nil
		}

		let generatedDatetime = String(cString: stringPointer)
		pactffi_free_string(stringPointer)

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
    
	/// `true` when all expected requests have successfully matched
	var requestsMatched: Bool {
		pactffi_mock_server_matched(port)
	}

	/// Descripton of mismatching requests
	var mismatchDescription: String {
		guard let mismatches = pactffi_mock_server_mismatches(port) else {
			return "No response! There might be something fishy going on with your Mock Server..."
		}

		let errorDescription = VerificationErrorHandler(mismatches: String(cString: mismatches)).description
		return errorDescription
	}

	/// Creates a mock server with pact data on a given port.
	///
	/// - Parameters:
	///   - pact: Pact data
	///   - port: The port on which to run mock server; use `nil` for a random port.
	///
	func createMockServer(pact: Data, port: Int32? = nil) throws -> Int32 {
        let tryPort = port ?? Self.randomPort
        Logger.log(message: "Starting mock server on port \(tryPort)")
        
		let serverPort = pactffi_create_mock_server(String(data: pact, encoding: .utf8), "\(socketAddress):\(tryPort)", tls)
        guard serverPort > 1_200 else {
            throw MockServerError(code: Int(serverPort))
        }
        
        Logger.log(message: "Mock server started on port \(serverPort)")
        return serverPort
	}

	/// Writes the Pact file to disk
    func writePactContractFile(port: Int32, pactDir: String, merge: Bool) throws -> String {
        try FileManager.default.createDirectory(atPath: pactDir, withIntermediateDirectories: true, attributes: nil)
		
        let overwrite = !merge
		Logger.log(message: "Writing pact contract in \(pactDir) using mock server on port: \(port). Overwrite flag set to \(overwrite).")
		let writeResult = pactffi_write_pact_file(port, pactDir, overwrite)

		guard writeResult == 0 else {
            throw MockServerError(code: Int(writeResult))
		}

        return "Pact written to \(pactDir)"
	}

	/// Shuts down the mock server and releases the socket address
	func shutdownMockServer() {
		if port != 0 {
			Logger.log(message: "Shutting down mock server on port \(port)")
            if pactffi_cleanup_mock_server(port) == false {
                Logger.log(message: "Failed to shut down mock server!")
            }
            port = 0
		}
	}

}
