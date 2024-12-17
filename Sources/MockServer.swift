//
//  Created by Marko Justinek on 10/5/21.
//  Copyright © 2020 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
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

	/// Network transfer protocol
	public enum TransferProtocol: Int {
		case standard
		case secure

		internal var `protocol`: String {
			switch self {
			case .standard: return "http"
			case .secure: return "https"
			}
		}
	}

	// MARK: - Properties

	/// The URL on which MockServer is running.
	public var baseUrl: URL {
		var components = URLComponents()
		components.scheme = transferProtocol.protocol
		components.port = Int(port)
		components.host = socketAddress

		return components.url!
	}

	private let socketAddress = "127.0.0.1"
	private let pact: Pact
	private let transferProtocol: TransferProtocol
	private let ffiProvider: PactFFIProviding

	// `port` is a var to support Linux platforms
	public private(set) var port: Int32 = 0

	// MARK: - Lifecycle

	/// Creates a MockServer on a random port.
	///
	/// - Throws: ``MockServer/Error`` on error.
	/// - Parameters:
	///   - pact: The ``Pact`` to create the server with.
	///   - transferProtocol: The protocol to use when communicating with the mock server; defaults to `.standard`.
	///   - port: The port on which to run mock server; use `nil` for a random port.
	convenience public init(pact: Pact, transferProtocol: TransferProtocol = .standard, port: Int32? = nil) throws {
		try self.init(pact: pact, transferProtocol: transferProtocol, port: port, ffiProvider: DefaultPactFFIProvider())
	}

	/// Fetch the CA Certificate used to generate the self-signed certificate for the TLS mock server.
	public var tlsCACertificate: String? {
		guard let cert = ffiProvider.tlsCACertificate() else {
			return nil
		}
		defer { ffiProvider.stringRelease(cert: cert) }

		return cert
	}

	deinit {
		if port != 0 {
			Logging.log(.debug, message: "Shutting down mock server on port \(port)...")
			if ffiProvider.mockServerCleanup(port: port) == false {
				Logging.log(.debug, message: "Failed to shut down mock server!")
			}
		}
	}

	// MARK: - Internal
	/// Creates a MockServer on a random port with provided FFI provider.
	///
	/// - Throws: ``MockServer/Error`` on error.
	/// - Parameters:
	///   - pact: The ``Pact`` to create the server with.
	///   - transferProtocol: The protocol to use when communicating with the mock server; defaults to `.standard`.
	///   - port: The port on which to run mock server; use `nil` for a random port.
	///   - ffiProvider: The implementation or a wrapper for Pact FFI provider.
	internal init(
		pact: Pact,
		transferProtocol: TransferProtocol = .standard,
		port: Int32? = nil,
		ffiProvider: PactFFIProviding
	) throws {
		self.ffiProvider = ffiProvider
		self.transferProtocol = transferProtocol
		self.pact = pact

		let tryPort = port ?? Self.randomPort
		Logging.log(.debug, message: "Starting mock server on \(socketAddress):\(tryPort)...")

		let result = try self.ffiProvider.mockServerForTransferProtocol(
			pactHandle: pact.handle,
			socketAddress: socketAddress,
			port: tryPort,
			transferProtocol: transferProtocol
		)

		self.port = result
		Logging.log(.debug, message: "Mock server started on port \(result)")
	}

	// MARK: - Interface

	/// - Returns: `true` when all expected requests have successfully matched.
	public var requestsMatched: Bool {
		guard port > 0 else {
			return false
		}

		return ffiProvider.mockServerMatched(port: port)
	}

	/// Get a JSON string representing the mismatches following interaction testing.
	public var mismatchesJSON: String? {
		guard port > 0 else {
			return nil
		}

		return ffiProvider.mockServerMismatches(port: port)
	}

	/// Get a string representing the mock server logs following interaction testing
	///
	/// - Note: This needs the memory `buffer` log sink to be setup before the mock server is started.
	/// - Returns: Log string.
	public var logs: String {
		if port > 0, let logs = ffiProvider.mockServerLogs(port: port) {
			return logs
		}
		return "ERROR: Unable to retrieve mock server logs"
	}
}

// MARK: - Error Extensions

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

// MARK: - Private

private extension MockServer {
	/// Finds an unsued port on Darwin. Returns `0` on Linux.
	///
	static var randomPort: Int32 {
		#if os(Linux)
		return 0
		#else
		// Darwin doesn't open a random available port if `0` value is sent to pactffi_create_mock_server(_:_:_:)
		return SocketBinder.unusedPort()
		#endif
	}
}
