//
//  Created by Marko Justinek on 28/10/2022.
//  Copyright © 2022 Marko Justinek. All rights reserved.
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

public protocol VerifierInterface {

	/// Triggers the provider verification task
	@available(*, deprecated, message: "Use the handle to instance approach")
	func verifyProvider(options args: String) -> Result<Bool, ProviderVerificationError>

	/// Executes the provider verification task
	///
	/// - returns: `true` when verification succeeds or `ProviderVerificationError` when verfication fails
	func verify() -> Result<Bool, ProviderVerificationError>

	/// Set the provider details for the Pact verifier.
	///
	/// Any `nil` value from the URL parameters will be replaced with the default value for that parameter.
	///
	/// - Parameters:
	///   - name: The provider name
	///   - url: The URL of the provider to verify
	///
	/// - Returns: Instance of `self`
	///
	@discardableResult
	func setProviderInfo(name: String, url: URL) -> VerifierInterface

	/// Sets the filters for the Pact verifier
	///
	/// - Parameter:
	///   - description: Description in form of regular expression
	///   - state: The state to filter
	///   - noState: A flag to filter no state
	///
	/// - Returns: Instance of `self`
	///
	@discardableResult
	func setFilter(description: String?, state: String?, noState: Bool) -> VerifierInterface

	/// Sets the provider state for the Pact verifier
	///
	/// - Parameters:
	///   - url: ??
	///   - teardown: ??
	///   - body: ??
	///
	/// - Returns: Instance of `self`
	///
	@discardableResult
	func setProviderState(url: URL, teardown: Bool, body: Bool) -> VerifierInterface

	/// Sets the options used by the verifier when calling the provider
	///
	/// - Parameters:
	///   - disableSSL: Flag setting the SSL verification
	///   - timeout: Sets the timeout
	///
	/// - Returns: Instance of `self`
	///
	@discardableResult
	func setVerificationOptions(disableSSL: Bool, timeout: UInt) -> VerifierInterface

	/// Adds a Pact directory as a source to verify
	///
	/// All pacts from the directory that match the provider name will be verified.
	///
	/// - Parameter directory: The absolute path to the directory containing Pacts
	///
	/// - Returns: Instance of `self`
	///
	@discardableResult
	func verifyPactsInDirectory(_ directory: String) -> VerifierInterface

	/// Adds a Pact file as a source to verify
	///
	/// - Parameter file: The absolute path to the Pact file
	///
	/// - Returns: Instance of `self`
	///
	@discardableResult
	func verifyPactFile(_ file: String) -> VerifierInterface

	/// Adds a URL as a source to verify
	///
	/// The Pact file will be fetched from the URL.
	///
	/// - Parameters:
	///   - url: The url of the Pact file
	///   - authentication: The authentication if required for the url
	///
	/// - Returns: Instance of `self`
	///
	@discardableResult
	func verifyPactAtURL(url: URL, authentication: Either<SimpleAuth, Token>?) -> VerifierInterface

	/// Adds a Pact broker as a source to verify
	///
	/// This will fetch all the Pact files from the broker that match the provider name.
	///
	/// - Parameters:
	///   - urlString: The URL of Pact broker as `String`
	///   - authentication: Optional authentication on the provided URL
	///
	/// - Returns: Instance of `self`
	///
	@discardableResult
	func verifyPactsAtPactBroker(urlString: String, authentication: Either<SimpleAuth, Token>?) -> VerifierInterface

	/// Adds a Pact broker as a source to verify
	///
	/// This will fetch all the pact files from the broker that match the provider name and the consumer version selectors.
	/// See [Consumer Version Selectors](https://docs.pact.io/pact_broker/advanced_topics/consumer_version_selectors) for more.
	///
	/// - Parameters:
	///   - url: The URL of broker
	///   - authentication: Authentication required for the pact broker
	///   - providerTags: The provider tags to verify against (deprecated)
	///   - providerBranch: The branch name of the provider to verify
	///   - versionSelectors: Version selectors defining which consumer version(s) to verify
	///   - consumerTags: The consumer tags to verify against (deprecated)
	///   - enablePending: Flag indicating whether to verify pending pacts
	///   - includeWIPPactsSince: Include all WIP pacts since provided date
	///
	/// - returns: Instance of `self`
	///
	@discardableResult
	func verifyPactsAtPactBroker( // swiftlint:disable:this function_parameter_count
		url: URL,
		authentication: Either<SimpleAuth, Token>,
		providerTags: [String],
		providerBranch: String?,
		versionSelectors: [VersionSelector],
		consumerTags: [String],
		enablePending: Bool,
		includeWIPPactsSince: Date?
	) throws -> VerifierInterface

	/// Sets custom headers to be added to the requests made to the provider
	///
	/// - parameter headers: Header values where KEY and VALUE contain ASCII characters (32-127) only
	///
	/// - returns: Instance of `self`
	///
	@discardableResult
	func setCustomHeaders(_ headers: [String: String]) -> VerifierInterface

	/// Sets the options used when publishing verification results to the Pact broker
	///
	/// - Parameters:
	///   - providerVersion: Version of the provider to publish
	///   - providerBranch: Name of the branch used for verification
	///   - buildURL: URL to the build which ran the verification
	///   - providerTags: Collection of tags for the provider
	///
	/// - Returns: Instance of `self`
	///
	@discardableResult
	func setPublishOptions(providerVersion: String, providerBranch: String, buildURL: URL, providerTags: [String]) -> VerifierInterface

}
