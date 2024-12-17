//
//  Created by Oliver Jones on 15/12/2022.
//  Copyright © 2022 Oliver Jones. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

public final class PactBuilder {

	public enum Error {
		/// Thrown when the Pact fails to verify.
		case pactFailure([PactVerificationFailure])
	}

	public struct ConsumerContext: Sendable {

		/// The base URL of the mock server.
		public let mockServerURL: URL

		public init(mockServerURL: URL) {
			self.mockServerURL = mockServerURL
		}
	}

	public struct Config: Sendable {
		/// The directory in to which Pacts are written.
		public let pactDirectory: String

		public init(pactDirectory: String) {
			self.pactDirectory = pactDirectory
		}
	}

	private let pact: Pact
	private let config: Config

	public init(pact: Pact, config: Config) {
		self.pact = pact
		self.config = config
	}

	/// Create a new `Interaction`.
	///
	/// - parameter description - The interaction description. It needs to be unique for each interaction.
	public func uponReceiving(_ description: String) -> Interaction {
		pact.uponReceiving(description)
	}

	/// Verify the configured interactions.
	///
	/// - Throws: An ``Error/pactFailure(_:)`` if the pact fails to verify or a ``MockServer/Error`` if the mock server fails.
	public func verify(handler: (ConsumerContext) throws -> Void) throws {
		let mockServer = try MockServer(pact: pact, transferProtocol: .standard)

		try handler(ConsumerContext(mockServerURL: mockServer.baseUrl))

		try verifyInternal(mockServer: mockServer)
	}

	/// Verify the configured interactions.
	///
	/// - Throws: An ``Error/pactFailure(_:)`` if the pact fails to verify or a ``MockServer/Error`` if the mock server fails.
	public func verify(handler: @Sendable (ConsumerContext) async throws -> Void) async throws {
		let mockServer = try MockServer(pact: pact, transferProtocol: .standard)

		try await handler(ConsumerContext(mockServerURL: mockServer.baseUrl))

		try verifyInternal(mockServer: mockServer)
	}

	/// Verify the interactions after the consumer client has been invoked
	/// - Parameters:
	///   - mockServer: The ``MockServer`` instance.
	private func verifyInternal(mockServer: MockServer) throws {
		guard mockServer.requestsMatched else {
			let failures = try JSONDecoder().decode([PactVerificationFailure].self, from: mockServer.mismatchesJSON?.data(using: .utf8) ?? Data())
			throw Error.pactFailure(failures)
		}

		try pact.writePactFile(directory: config.pactDirectory, overwrite: false)
	}
}

extension PactBuilder.Error: LocalizedError {
	public var failureReason: String? {
		switch self {
		case .pactFailure(let mismatches):
			return String.localizedStringWithFormat(NSLocalizedString("Pact Failure (see below):\n%@", comment: ""), mismatches.map(\.description).joined(separator: "\n---\n"))
		}
	}
}
