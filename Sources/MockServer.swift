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

	// MARK: - Properties

	/// The URL on which MockServer is running.
	public var baseUrl: String {
		"\(transferProtocol.protocol)://\(socketAddress):\(port)"
	}

	private let socketAddress = "127.0.0.1"

	// `port` is a var to support Linux platforms
	private var port: Int32 = 0
	private var transferProtocol: TransferProtocol = .standard
	private var tls: Bool {
		transferProtocol == .secure ? true : false
	}

	private let directoryURL: URL?
	private let merge: Bool

	// MARK: - Lifecycle

	/// Initializes a MockServer on a random port
	///
	/// - Parameters:
	///   - directory: The directory URL to write the Pact contract into
	///   - merge: Whether to merge interactions with an existing Pact contract.
	///
	public init(
		directory: URL? = nil,
		merge: Bool = true
	) {
		self.port = Self.randomPort
		self.merge = merge
		self.directoryURL = directory
	}

	deinit {
		shutdownMockServer()
	}

	// MARK: - Interface

	/// Spins up a mock server with expected interactions defined in the provided Pact
	///
	/// - Parameters:
	///   - pact: The pact contract
	///   - protocol: HTTP protocol
	///   - completion: A completion block called when setup completes
	///
	public func setup(pact: Data, protocol: TransferProtocol = .standard, completion: (Result<Int, MockServerError>) -> Void) {
		Logger.log(message: "Setting up pact mock server for consumer verification", data: pact)
		transferProtocol = `protocol`

		Logger.log(message: "Starting up mock server for pact interaction test")
		port = createMockServer(pact: pact)

		guard port > 1_200 else {
			return completion(.failure(MockServerError(code: Int(port))))
		}

		Logger.log(message: "Mock server started on port \(port)")
		return completion(.success(Int(port)))
	}

	/// Verifies all interactions passed to mock server
	///
	/// - Parameters:
	///   - completion: A completion block called when setup completes
	///
	/// By default pact files are written to `/tmp/pacts`.
	/// Use `PACT_OUTPUT_DIR` environment variable with absolute path to your custom path in schema `run` configuration.
	///
	public func verify(completion: (Result<Bool, VerificationError>) -> Void) {
		guard requestsMatched else {
			completion(.failure(.reason(mismatchDescription)))
			shutdownMockServer()
			return
		}
		completion(.success(true))
		shutdownMockServer()
	}

	/// Finalises Pact tests by writing the pact contract file to disk
	///
	/// - Parameters:
	///   - pact: The Pact contract to write
	///   - completion: A completion block called when setup completes
	///
	public func finalize(pact: Data, completion: ((Result<String, MockServerError>) -> Void)?) {
		Logger.log(message: "Starting up mock server to finalize writing pact with data:", data: pact)
		let randomPort = Self.randomPort

		Logger.log(message: "Starting mock server on port \(randomPort)")
		port = createMockServer(pact: pact, port: randomPort)

		guard port > 1_200 else {
			completion?(.failure(MockServerError(code: Int(port))))
			return
		}

		Logger.log(message: "Mock server started on port \(port). Attempting to write pact file with data:", data: pact)
		writePactContractFile(port: port) {
			switch $0 {
			case .success(let message):
				completion?(.success(message))
			case .failure(let error):
				completion?(.failure(error))
			}
		}

		shutdownMockServer()
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
	static func generate_value(regex: String) -> String? {
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
	static func generate_date(format: String) -> String? {
		guard let stringPointer = pactffi_generate_datetime_string(format).ok._0 else {
			return nil
		}

		let generatedDatetime = String(cString: stringPointer)
		pactffi_free_string(stringPointer)

		return generatedDatetime
	}

	/// Finds an unsued port on Darwin. Returns ``0`` on Linux.
	private static var randomPort: Int32 {
		#if os(Linux)
		return 0
		#else
		// Darwin doesn't seem to use a random available port if ``0`` is sent to pactffi_create_mock_server(_:_:_:)
		return SocketBinder.unusedPort()
		#endif
	}

}

// MARK: - Private

private extension MockServer {

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
	///   - port: The port on which to run mock server
	///
	/// If value for ``port`` is not provider, the ``port`` from ``MockServer`` instance is used.
	///
	func createMockServer(pact: Data, port: Int32? = nil) -> Int32 {
		pactffi_create_mock_server(String(data: pact, encoding: .utf8), "\(socketAddress):\(port ?? self.port)", tls)
	}

	/// Writes the Pact file to disk
	func writePactContractFile(port: Int32? = nil, completion: (Result<String, MockServerError>) -> Void) {
		guard PactFileManager.isPactDirectoryAvailable() else {
			completion(.failure(.failedToWriteFile))
			return
		}

		Logger.log(message: "Writing pact contract in \(self.pactDir) using mock server on port: \(port ?? self.port). Overwrite flag set to \(self.merge).")
		let writeResult = pactffi_write_pact_file(port ?? self.port, self.pactDir, !self.merge)

		guard writeResult == 0 else {
			completion(.failure(MockServerError(code: Int(writeResult))))
			return
		}

		completion(.success("Pact written to \(self.pactDir)"))
	}

	/// Shuts down the mock server and releases the socket address
	func shutdownMockServer(on port: Int32? = nil) {
		let port = port ?? self.port
		if port > 0 {
			Logger.log(message: "Shutting down mock server on port \(port)")
			pactffi_cleanup_mock_server(port)
		}
	}

	/// Defines the directory to write the Pact contract file into as String
	var pactDir: String {
		if let directory = directoryURL, directory.isFileURL {
			return directory.path
		} else {
			Logger.log(message: "None or invalid directory URL provided.")
			return PactFileManager.pactDirectoryPath
		}
	}

}
