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

	/// URL of the provider being verified
	///
	/// When specified alongside ``pactURLs``, ``pactFiles`` or ``pactDirs`` it will run
	/// the verification once for each dynaic pact (Broker) discovered and user specified (URL) pact.
	///
	let baseURL: String

	/// URL of the build to associate with the published verification results
	let buildURL: String?

	/// Validates only against listed consumers
	let filterConsumers: [String]?

	/// Validates only against interactions whose descriptions match the provided filter
	let filterDescriptions: [String]?

	/// Validates only against interactions whose provider states match the provided filter
	let filterStates: [String]?

	/// Validates only against interactions that do not have a provide state
	let filterNoState: Bool

	/// HTTP paths to Pact files
	///
	/// When specified alongside ``pactURLs``, ``pactFiles`` or ``pactDirs`` it will run
	/// the verification once for each dynaic pact (Broker) discovered and user specified (URL) pact.
	///
	let pactURLs: [String]?

	/// Local paths to Pact files
	///
	/// When specified alongside ``pactURLs``, ``pactFiles`` or ``pactDirs`` it will run
	/// the verification once for each dynaic pact (Broker) discovered and user specified (URL) pact.
	///
	let pactFiles: [String]?

	/// Local paths to directories containing Pact files
	///
	/// When specified alongside ``pactURLs``, ``pactFiles`` or ``pactDirs`` it will run
	/// the verification once for each dynaic pact (Broker) discovered and user specified (URL) pact.
	///
	let pactDirs: [String]?

	/// Selectors are the way we specify which pacticipants and versions we want to use when configuring verifications
	///
	/// See [https://docs.pact.io/selectors](https://docs.pact.io/selectors) for more.
	///
	let consumerVersionSelectors: [VersionSelector]?

	/// Retrieve the latest pacts with this consumer version tag
	let consumerTags: [String]?

	/// Tags to apply to the provider application version
	let providerTags: [String]?

	/// The endpoint to post current provider state to on the Provider API
	@available(*, deprecated, message: "Use StateHandlers instead")
	let providerStatesSetupURL: String

	/// The name of the Providing service
	let providerName: String

	/// The provider version being verified
	let providerVersion: String

	/// Pact broker configuration
	let broker: PactBroker?

	/// Framework returns an error if no pacts were found
	// TODO: - Perhaps this should be in `PactBroker` type?
	let failIfNoPactFound: Bool

	/// A mapped list of message states to functions that are used to setup a given provider state prior to the message verification step
	let stateHandlers: [StateHandler]?

// TODO: - figure this one out
//	let beforeEachHook

// TODO: - figure this one out
//	let afterEachHook

// TODO: - figure this one out
//	let requestFilter: Proxy.Middleware

// TODO: - figure this one out
	/// Custom TLS Configuration to use when making the requests to/from
	/// the Provider API.
	///
	/// Useful for setting custom certificates, MASSL etc.
	///
//	let tlsConfig: TLS.Config

	/// Allow pending pacts to be included in verification
	///
	/// See [https://docs.pact.io/pact_broker/advanced_topics/pending_pacts/](https://docs.pact.io/pact_broker/advanced_topics/pending_pacts/) for more.
	let enablePending: Bool

	/// Pull in new WIP pacts from _any_ tag
	///
	/// See [https://pact.io/wip](https://pact.io/wip) for more.
	///
	let includeWIPPactsSice: Date

}

/*

logLevel:
-l, --loglevel <loglevel>:	Log level (defaults to warn) [possible values: error, warn, info, debug,trace, none]

*/
