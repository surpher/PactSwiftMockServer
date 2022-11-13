//
//  Created by Marko Justinek on 18/8/21.
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

#if SWIFT_PACKAGE
import PactMockServer
#endif

/// Used to verify the provider side of a pact contract
public final class Verifier: VerifierInterface {

	public struct PublishOptions {
		let providerVersion: String
		let buildURL: URL
		let tags: [String]
		let providerBranch: String

		public init(providerVersion: String, buildURL: URL, tags: [String], providerBranch: String) {
			self.providerVersion = providerVersion
			self.buildURL = buildURL
			self.tags = tags
			self.providerBranch = providerBranch
		}
	}

	let verifierHandle: OpaquePointer?

	// MARK: - Lifecycle

	@available(*, deprecated, message: "Use init(name:version:) instead")
	public init() {
		verifierHandle = nil
	}

	/// Initialises a `Verifier` object and sets a handle to the mock server
	///
	/// - Parameters:
	///   - name: Name of the application to verify
	///   - version: Version of the application to verify
	///
	public init?(name: String, version: String) {
		guard let verifier = pactffi_verifier_new_for_application(name, version) else { return nil }
		verifierHandle = verifier
	}

	deinit {
		verifierHandle.map { pactffi_verifier_shutdown($0) }
	}

	// MARK: - Interface

	/// Triggers the provider verification task by replaying the requests from provided contracts
	///
	/// - Parameters:
	///   - options: Newline delimited args
	///
	/// See [pact_verifier_cli](https://docs.pact.io/implementation_guides/rust/pact_verifier_cli) for more
	///
	@available(*, deprecated, message: "Use .verify() with combination of other options setters instead.")
	public func verifyProvider(options args: String) -> Result<Bool, ProviderVerificationError> {
		Logger.log(message: "VerificationOptions", data: Data(args.utf8))
		let verificationResult = pactffi_verify(args)

		// Errors are returned as non-zero numeric values
		guard verificationResult == 0 else {
			return .failure(ProviderVerificationError(code: verificationResult))
		}

		// Verification completed successfully
		return .success(true)
	}

	/// Sets the provider details for the Pact verifier
	public func setProviderInfo(name: String, url: URL) -> VerifierInterface {
		pactffi_verifier_set_provider_info(verifierHandle, name, url.scheme, url.host, UInt16(url.port ?? 8_080), url.path)
		return self
	}

	/// Sets the filters for the Pact verifier
	public func setFilter(description: String? = nil, state: String? = nil, noState: Bool = false) -> VerifierInterface {
		pactffi_verifier_set_filter_info(verifierHandle, description, state, noState ? 1 : 0)
		return self
	}

	/// Sets the provider state for the Pact verifier
	public func setProviderState(url: URL, teardown: Bool = false, body: Bool = false) -> VerifierInterface {
		pactffi_verifier_set_provider_state(verifierHandle, url.absoluteString, teardown ? 1 : 0, body ? 1 : 0)
		return self
	}

	/// Sets the options used by the verifier when calling the provider
	public func setVerificationOptions(disableSSL: Bool, timeout: UInt) -> VerifierInterface {
		pactffi_verifier_set_verification_options(verifierHandle, disableSSL ? 1 : 0, timeout)
		return self
	}

	/// Adds a Pact directory as a source to verify.
	public func verifyPactsInDirectory(_ directory: String) -> VerifierInterface {
		pactffi_verifier_add_directory_source(verifierHandle, directory)
		return self
	}

	/// Adds a Pact file as a source to verify
	public func verifyPactFile(_ file: String) -> VerifierInterface {
		pactffi_verifier_add_file_source(verifierHandle, file)
		return self
	}

	/// Adds a URL as a source to verify
	public func verifyPactAtURL(url: URL, authentication: Either<SimpleAuth, Token>?) -> VerifierInterface {
		switch authentication {
		case let .auth(auth):
			pactffi_verifier_url_source(verifierHandle, url.absoluteString, auth.username, auth.password, nil)
		case let .token(token):
			pactffi_verifier_url_source(verifierHandle, url.absoluteString, nil, nil, token.value)
		case .none:
			pactffi_verifier_url_source(verifierHandle, url.absoluteString, nil, nil, nil)
		}

		return self
	}

	/// Adds a Pact broker as a source to verify
	public func verifyPactsAtPactBroker(urlString: String, authentication: Either<SimpleAuth, Token>? = nil) -> VerifierInterface {
		switch authentication {
		case let .auth(auth):
			pactffi_verifier_broker_source(verifierHandle, urlString, auth.username, auth.password, nil)
		case let .token(token):
			pactffi_verifier_broker_source(verifierHandle, urlString, nil, nil, token.value)
		case .none:
			pactffi_verifier_broker_source(verifierHandle, urlString, nil, nil, nil)
		}

		return self
	}

	/// Verifies pact(s) at given broker with options
	public func verifyPactsAtPactBroker(
		url: URL,
		authentication: Either<SimpleAuth, Token>,
		providerTags: [String] = [],
		providerBranch: String? = nil,
		versionSelectors: [VersionSelector] = [],
		consumerTags: [String] = [],
		enablePending: Bool = false,
		includeWIPPactsSince: Date? = nil
	) throws -> VerifierInterface {
		let authentication = extractBrokerAuthentication(from: authentication)
		let arrayOfVersionSelectorsAsJSON = try versionSelectorsAsJSONStrings(versionSelectors)

		var cargsProviderTags = mapToArrayOfPointers(array: providerTags)
		var cargsConsumerVersionSelectors = mapToArrayOfPointers(array: arrayOfVersionSelectorsAsJSON)
		var cargsConsumerVersionTags = mapToArrayOfPointers(array: consumerTags)

		pactffi_verifier_broker_source_with_selectors(
			verifierHandle,
			url.absoluteString,
			authentication.username,
			authentication.password,
			authentication.token,
			enablePending ? 1 : 0,
			wipPactsSinceDate(includeWIPPactsSince),
			&cargsProviderTags,
			UInt16(providerTags.count),
			providerBranch,
			&cargsConsumerVersionSelectors,
			UInt16(arrayOfVersionSelectorsAsJSON.count),
			&cargsConsumerVersionTags,
			UInt16(consumerTags.count)
		)

		freeMemFor(cargsProviderTags, cargsConsumerVersionSelectors, cargsConsumerVersionTags)

		return self
	}

	/// Sets custom headers to be added to the requests made to the provider
	///
	/// - parameter headers: Header values where KEY and VALUE contain ASCII characters (32-127) only
	///
	public func setCustomHeaders(_ headers: [String: String]) -> VerifierInterface {
		headers.forEach {
			pactffi_verifier_add_custom_header(verifierHandle, $0, $1)
		}

		return self
	}

	/// Set the options used when publishing verification results to the Pact broker
	public func setPublishOptions(providerVersion: String, providerBranch: String, buildURL: URL, providerTags: [String] = []) -> VerifierInterface {
		let cargsProviderTags = mapToArrayOfPointers(array: providerTags)

		pactffi_verifier_set_publish_options(
			verifierHandle,
			providerVersion,
			buildURL.absoluteString,
			cargsProviderTags,
			UInt16(providerTags.count),
			providerBranch
		)

		freeMemFor(cargsProviderTags)

		return self
	}

	/// Executes the provider verification task
	///
	/// - returns: `true` when on verification success or `ProviderVerificationError` on failure
	///
	@discardableResult
	public func verify() -> Result<Bool, ProviderVerificationError> {
		let verificationResult = pactffi_verifier_execute(verifierHandle)

		return verificationResult == 0 ? .success(true) : .failure(ProviderVerificationError(code: verificationResult))
	}

}

// MARK: - Private

private extension Verifier {

	func extractBrokerAuthentication(from authentication: Either<SimpleAuth, Token>) -> (username: String?, password: String?, token: String?) {
		switch authentication {
		case let .auth(auth):
			return (username: auth.username, password: auth.password, token: nil)
		case let .token(token):
			return (username: nil, password: nil, token: token.value)
		}
	}

	func wipPactsSinceDate(_ date: Date?) -> String? {
		guard let date = date else { return nil }

		let dateFormatter = ISO8601DateFormatter()
		dateFormatter.formatOptions = [.withFullDate]

		return dateFormatter.string(from: date)
	}

	/// Converts an array of `String`s into an array of `UnsafePointer`s
	///
	/// - parameter array: The array of `Strings`
	/// - returns: An array of pointers to input array's values
	///
	/// - warning: Memory must be explicitly released.
	///
	func mapToArrayOfPointers(array: [String?]) -> [UnsafePointer<Int8>?] {
		array.map { $0.flatMap { UnsafePointer<Int8>(strdup($0)) } }
	}

	/// Frees memory allocation for an array of `UnsafePointers`
	func freeMemFor<T>(_ pointers: [UnsafePointer<T>?]...) {
		pointers.forEach { pointer in
			for ptr in pointer { free(UnsafeMutablePointer(mutating: ptr)) }
		}
	}

	func versionSelectorsAsJSONStrings(_ versionSelectors: [VersionSelector]) throws -> [String] {
		let encodedVersionSelectors = try versionSelectors.compactMap {
			let encodedSelector = try JSONEncoder().encode($0)
			return String(data: encodedSelector, encoding: .utf8)
		}
		return encodedVersionSelectors
	}

}
