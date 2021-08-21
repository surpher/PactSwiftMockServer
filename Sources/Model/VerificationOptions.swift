//
//  Created by Marko Justinek on 19/8/21.
//  Copyright © 2021 Marko Justinek. All rights reserved.
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

/// Defines the options to use when verifying a provider
public struct VerificationOptions {

	// MARK: - Types

	public enum LogLevel: String {
		case error
		case warn
		case info
		case debug
		case trace
		case none
	}

	public enum PactLocation {
		case directories([String])
	}

	// MARK: - Properties

	/// The port of provider being verified
	let port: Int

	/// URL of the provider being verified
	let providerURL: String?

	/// Validates only against interactions that do not have a provider state
	let filterNoState: Bool

	/// Local paths to directories containing Pact files
	let pactDirs: [String]?

	/// Sets the log level
	let logLevel: LogLevel

	// MARK: - Initialization

	/// Defines the options to use when verifying a provider
	///
	/// - Parameters:
	///   - port: The port on which the provider being verified is running
	///   - providerURL: The URL of provider being verified (defaults to ``http://localhost``)
	///   - pactLocation: The locations of pacts
	///   - filterNoState: Whether to only validate interactions that do not have a defined state
	///   - logLevel: Logging level
	///
	public init(
		port: Int,
		pactLocation: PactLocation,
		providerURL: String? = nil,
		filterNoState: Bool = false,
		logLevel: LogLevel = .warn
	) {
		self.providerURL = providerURL
		self.port = port
		self.filterNoState = filterNoState
		self.logLevel = logLevel

		switch pactLocation {
		case .directories(let pactDirs): self.pactDirs = pactDirs
		}
	}

}

extension VerificationOptions {

	/// Newline delimited verification arguments
	internal var args: String {
		var args = [String]()

		// Set verified provider port
		args.append("-p\n\(self.port)")

		// Set verified provider url
		if let providerURL = providerURL {
			args.append("--hostname\n\(providerURL)")
		}

		// Set directories option
		if let pactDirs = pactDirs, pactDirs.isEmpty == false {
			pactDirs.forEach { args.append("--dir\n\($0)") }
		}

		// Set no-state filter
		if filterNoState {
			args.append("--filter-no-state\ntrue")
		}

		// Set logging level
		args.append("--loglevel\n\(self.logLevel.rawValue)")

		// Convert to a ``String``
		return args.joined(separator: "\n")
	}

}
