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

	/// Sets the provider details for the Pact verifier
	///
	/// - parameter info: Provider information
	///
	/// - returns: Instance of `self`
	///
	func setInfo(_ info: Provider.Info) -> VerifierInterface

	/// Sets the filter defining which pacts to verify
	///
	/// - parameter filter: Object defining which Pacts to filter
	///
	/// - returns: Instance of `self`
	///
	func setFilter(_ filter: Provider.Filter) -> VerifierInterface

	/// Sets the provider state
	///
	/// - parameter state: The state of the provider to set before running the verification
	///
	/// - returns: Instance of `self`
	///
	func setProviderState(_ state: Provider.State) -> VerifierInterface

	/// Sets verification options
	///
	/// - parameter options: The verifier options
	///
	/// - returns: Instance of `self`
	///
	func setVerificationOptions(_ options: Verifier.Options) -> VerifierInterface

	/// Verifies pact(s) at given source
	///
	/// - parameter source: The object defining the source of Pacts
	///
	/// - returns: Instance of `self`
	///
	func verifyPactsAt(source: Source) -> VerifierInterface

	/// Verifies pact(s) at given broker with defined options
	///
	/// - Parameters:
	///   - broker: The Broker where Pacts are
	///   - provider: The provider to verify Pacts against
	///   - consumer: The consumer to to verify provider for
	///   - enablePending: Flag indicating whether to verify against pending pacts
	///   - includeWIPPactsSince: The date of WIP pacts to include in verification
	///
	/// - returns: Instance of `self`
	///
	func verifyPactsAt(broker: Broker, provider: Provider, consumer: Consumer, enablePending: Bool, includeWIPPactsSince: Date?) -> VerifierInterface

	/// Sets custom headers to be added to the requests made to the provider
	///
	/// - parameter headers: Header values where KEY and VALUE contain ASCII characters (32-127) only
	///
	/// - returns: Instance of `self`
	///
	func setCustomHeaders(_ headers: [String: String]) -> VerifierInterface

}
