//
//  Created by José Jeria on 20/7/2026.
//  Copyright © 2026 José Jeria. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

/// Typed options describing a provider verification run.
///
/// These map directly onto the handle-based `pactffi_verifier_*` API. They replace the
/// newline-delimited CLI argument string that the removed `pactffi_verify` used to take.
public struct VerificationOptions {

    /// The provider being verified.
    public struct Provider {

        /// The provider name. Pacts are matched against this name. Defaults to `"provider"`.
        public var name: String

        /// The scheme the provider is served over (`"http"` or `"https"`).
        public var scheme: String

        /// The provider host (eg `"localhost"`).
        public var host: String

        /// The provider port.
        public var port: UInt16

        /// The base path prefixed to every request. Defaults to `"/"`.
        public var path: String

        public init(
            name: String = "provider",
            scheme: String = "http",
            host: String = "localhost",
            port: UInt16,
            path: String = "/"
        ) {
            self.name = name
            self.scheme = scheme
            self.host = host
            self.port = port
            self.path = path
        }
    }

    /// Authentication for a Pact source (broker or URL).
    public enum Authentication {

        /// Basic auth with a username and password.
        case basic(username: String, password: String)

        /// Bearer token auth (eg PactFlow).
        case token(String)
    }

    /// Configuration for verifying pacts fetched from a Pact Broker.
    public struct Broker {

        /// The base URL of the Pact Broker.
        public var url: URL

        /// Optional authentication for the broker.
        public var authentication: Authentication?

        /// Whether to enable pending pacts.
        public var enablePending: Bool

        /// If set, includes work-in-progress pacts changed since this date.
        public var includeWIPPactsSince: Date?

        /// Provider tags to fetch pacts for.
        public var providerTags: [String]

        /// Provider branch to fetch pacts for.
        public var providerBranch: String?

        /// Consumer version selectors, each a JSON string as understood by the Pact Broker.
        public var consumerVersionSelectors: [String]

        /// Consumer version tags to fetch pacts for.
        public var consumerVersionTags: [String]

        public init(
            url: URL,
            authentication: Authentication? = nil,
            enablePending: Bool = false,
            includeWIPPactsSince: Date? = nil,
            providerTags: [String] = [],
            providerBranch: String? = nil,
            consumerVersionSelectors: [String] = [],
            consumerVersionTags: [String] = []
        ) {
            self.url = url
            self.authentication = authentication
            self.enablePending = enablePending
            self.includeWIPPactsSince = includeWIPPactsSince
            self.providerTags = providerTags
            self.providerBranch = providerBranch
            self.consumerVersionSelectors = consumerVersionSelectors
            self.consumerVersionTags = consumerVersionTags
        }
    }

    /// A source of pacts to verify.
    public enum Source {

        /// A single pact file at a path.
        case file(String)

        /// A directory of pact files. All matching the provider name are verified.
        case directory(String)

        /// A pact file fetched from a URL.
        case url(URL, authentication: Authentication?)

        /// Pacts fetched from a Pact Broker.
        case broker(Broker)
    }

    /// Restricts which interactions are verified.
    ///
    /// - Note: The FFI accepts a single description and a single state. Multiple values are not
    ///   supported by `pactffi_verifier_set_filter_info`.
    public struct Filter {

        /// Only verify interactions whose description matches this filter.
        public var description: String?

        /// Only verify interactions whose provider state matches this filter.
        public var state: String?

        /// Only verify interactions that have no provider state.
        public var noState: Bool

        public init(description: String? = nil, state: String? = nil, noState: Bool = false) {
            self.description = description
            self.state = state
            self.noState = noState
        }
    }

    /// Provider state change request configuration.
    public struct StateChange {

        /// URL to post provider state change requests to.
        public var url: URL

        /// Whether to make teardown requests after each interaction.
        public var teardown: Bool

        /// Whether the state change request body is sent as JSON (`true`) or as query parameters (`false`).
        public var body: Bool

        public init(url: URL, teardown: Bool = false, body: Bool = true) {
            self.url = url
            self.teardown = teardown
            self.body = body
        }
    }

    /// Publishing verification results back to a Pact Broker.
    public struct Publish {

        /// The provider version the results are published against.
        public var providerVersion: String

        /// Optional URL of the CI build to associate with the results.
        public var buildURL: URL?

        /// Provider tags to publish against.
        public var providerTags: [String]

        /// Provider branch to publish against.
        public var providerBranch: String?

        public init(
            providerVersion: String,
            buildURL: URL? = nil,
            providerTags: [String] = [],
            providerBranch: String? = nil
        ) {
            self.providerVersion = providerVersion
            self.buildURL = buildURL
            self.providerTags = providerTags
            self.providerBranch = providerBranch
        }
    }

    /// The provider being verified.
    public var provider: Provider

    /// The pact sources to verify. Evaluated in order.
    public var sources: [Source]

    /// Optional interaction filter.
    public var filter: Filter?

    /// Only verify pacts from these consumers. Empty means all consumers.
    public var consumerFilters: [String]

    /// Optional provider state change configuration.
    public var stateChange: StateChange?

    /// Optional publishing configuration.
    public var publish: Publish?

    /// Disables SSL certificate verification when talking to the provider.
    public var disableSSLVerification: Bool

    /// HTTP request timeout in milliseconds.
    public var requestTimeout: UInt64

    public init(
        provider: Provider,
        sources: [Source],
        filter: Filter? = nil,
        consumerFilters: [String] = [],
        stateChange: StateChange? = nil,
        publish: Publish? = nil,
        disableSSLVerification: Bool = false,
        requestTimeout: UInt64 = 5_000
    ) {
        self.provider = provider
        self.sources = sources
        self.filter = filter
        self.consumerFilters = consumerFilters
        self.stateChange = stateChange
        self.publish = publish
        self.disableSSLVerification = disableSSLVerification
        self.requestTimeout = requestTimeout
    }
}
