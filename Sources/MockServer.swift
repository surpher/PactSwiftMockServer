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
@_implementationOnly import PactSwiftToolbox

#if SWIFT_PACKAGE
import PactMockServer
#endif

public class MockServer {

	// MARK: - Properties

	/// The URL on which MockServer is running.
	public var baseUrl: String {
		"\(transferProtocol.protocol)://\(socketAddress):\(port)"
	}

	let socketAddress = "127.0.0.1"
	var port: Int32 = 0
	var transferProtocol: TransferProtocol = .standard

	var tls: Bool {
		transferProtocol == .secure ? true : false
	}

	// MARK: - Lifecycle

	/// Initializes a mock server object
	///
	public init() {
		// Intentionally left blank
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
		Logger.log(message: "Setting up Pact mock Server", data: pact)
		transferProtocol = `protocol`
		Logger.log(message: "Setting up MockServer for Pact interaction test")
		port = pactffi_create_mock_server(
			String(data: pact, encoding: .utf8),
			"\(socketAddress):0",
			tls
		)

		Logger.log(message: "MockServer started on port \(port)")

		return (port > 1_200)
			? completion(Result.success(Int(port)))
			: completion(Result.failure(MockServerError(code: Int(port))))
	}

	/// Verifies all interactions passed to `MockServer`.
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

	/// Finalises Pact tests by writing the Pact contract file to disk
	///
	/// - Parameters:
	///   - pact: The Pact contract to write
	///   - completion: A completion block called when setup completes
	///
	public func finalize(pact: Data, completion: ((Result<String, MockServerError>) -> Void)?) {
		Logger.log(message: "Starting up MockServer to finalize writing Pact with data:", data: pact)

		Logger.log(message: "Creating MockServer on a random port")
		port = pactffi_create_mock_server(
			String(data: pact, encoding: .utf8)?.replacingOccurrences(of: "\\", with: ""),
			"\(socketAddress):0",
			tls
		)
		Logger.log(message: "Created a MockServer on port \(port) to write a Pact contract file")

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

	/// Writes the Pact file to disk
	func writePactContractFile(port: Int32? = nil, completion: (Result<String, MockServerError>) -> Void) {
		guard PactFileManager.isPactDirectoryAvailable() else {
			completion(.failure(.failedToWriteFile))
			return
		}

		let pactDir = PactFileManager.pactDirectoryPath
		Logger.log(message: "Writing Pact contract in \(pactDir) using MockServer on port: \(port ?? self.port)")

		let writeResult = pactffi_write_pact_file(port ?? self.port, pactDir, true)
		guard writeResult == 0 else {
			completion(.failure(MockServerError(code: Int(writeResult))))
			return
		}
		completion(.success("Pact written to \(pactDir)"))
	}

	/// Shuts down the MockServer and releases the socket address
	func shutdownMockServer(on port: Int32? = nil) {
		let port = port ?? self.port
		if port > 0 {
			Logger.log(message: "Shutting down mock server on port \(port)")
			pactffi_cleanup_mock_server(port)
		}
	}

}
