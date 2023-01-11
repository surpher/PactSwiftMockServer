//
//  Created by Oliver Jones on 15/12/2022.
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

public final class PactBuilder {

	public enum Error {
		case pactFailure([PactVerificationFailure])
	}

	public struct ConsumerContext {
		public var mockServerURL: URL
	}

	public struct Config {
		public var pactDirectory: String

		public init(pactDirectory: String) {
			self.pactDirectory = pactDirectory
		}
	}

	private let pact: Pact
	private let config: Config

	private var interactions: [Interaction] = []

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
	public func verify(handler: (ConsumerContext) async throws -> Void) async throws {
		let mockServer = try MockServer(pact: pact, transferProtocol: .standard)

		try await handler(ConsumerContext(mockServerURL: mockServer.baseUrl))

		try verifyInternal(mockServer: mockServer)
	}

	/// Verify the interactions after the consumer client has been invoked
	/// - Parameters:
	///   - mockServer: The ``MockServer`` instance.
	private func verifyInternal(mockServer: MockServer) throws {
		guard mockServer.requestsMatched else {
			// TODO: log the verification mismatches

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
