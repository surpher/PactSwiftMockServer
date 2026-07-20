//
//  Created by Marko Justinek on 18/8/21.
//  Copyright © 2021 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

#if SWIFT_PACKAGE
import PactMockServer
#endif

/// Used to verify the provider side of a pact contract
public final class Verifier: ProviderVerifying {

    public init() {
        // Intentionally left blank
    }

    /// Triggers the provider verification task by replaying the requests from the provided contracts.
    ///
    /// Configures a verifier handle from `options` using the `pactffi_verifier_*` API, runs it, and
    /// tears it down.
    ///
    /// - Parameters:
    ///   - options: Typed provider verification options.
    ///
    public func verifyProvider(options: VerificationOptions) -> Result<Bool, ProviderVerificationError> {
        guard let handle = pactffi_verifier_new_for_application(Self.callingApp, Self.callingAppVersion) else {
            return .failure(.nullPointer)
        }
        defer { pactffi_verifier_shutdown(handle) }

        configure(handle, with: options)

        let verificationResult = pactffi_verifier_execute(handle)

        // Errors are returned as non-zero numeric values
        guard verificationResult == 0 else {
            return .failure(ProviderVerificationError(code: verificationResult))
        }

        return .success(true)
    }
}

// MARK: - Private

private extension Verifier {

    static let callingApp = "pact-swift"
    static let callingAppVersion = "2.0.0"

    /// Applies every option to the verifier `handle` through the granular FFI setters.
    func configure(_ handle: OpaquePointer, with options: VerificationOptions) {
        let provider = options.provider
        pactffi_verifier_set_provider_info(
            handle,
            provider.name.cString(using: .utf8),
            provider.scheme.cString(using: .utf8),
            provider.host.cString(using: .utf8),
            provider.port,
            provider.path.cString(using: .utf8)
        )

        _ = pactffi_verifier_set_verification_options(
            handle,
            options.disableSSLVerification ? 1 : 0,
            UInt(options.requestTimeout)
        )

        options.sources.forEach { add($0, to: handle) }

        if let filter = options.filter {
            pactffi_verifier_set_filter_info(
                handle,
                filter.description?.cString(using: .utf8),
                filter.state?.cString(using: .utf8),
                filter.noState ? 1 : 0
            )
        }

        if options.consumerFilters.isEmpty == false {
            withCStringArray(options.consumerFilters) { pointer, length in
                pactffi_verifier_set_consumer_filters(handle, pointer, length)
            }
        }

        if let stateChange = options.stateChange {
            pactffi_verifier_set_provider_state(
                handle,
                stateChange.url.absoluteString.cString(using: .utf8),
                stateChange.teardown ? 1 : 0,
                stateChange.body ? 1 : 0
            )
        }

        if let publish = options.publish {
            withCStringArray(publish.providerTags) { tags, tagsLength in
                _ = pactffi_verifier_set_publish_options(
                    handle,
                    publish.providerVersion.cString(using: .utf8),
                    publish.buildURL?.absoluteString.cString(using: .utf8),
                    tags,
                    tagsLength,
                    publish.providerBranch?.cString(using: .utf8)
                )
            }
        }
    }

    /// Registers a single pact source with the verifier `handle`.
    func add(_ source: VerificationOptions.Source, to handle: OpaquePointer) {
        switch source {
        case .file(let path):
            pactffi_verifier_add_file_source(handle, path.cString(using: .utf8))

        case .directory(let path):
            pactffi_verifier_add_directory_source(handle, path.cString(using: .utf8))

        case .url(let url, let authentication):
            pactffi_verifier_url_source(
                handle,
                url.absoluteString.cString(using: .utf8),
                authentication?.username?.cString(using: .utf8),
                authentication?.password?.cString(using: .utf8),
                authentication?.token?.cString(using: .utf8)
            )

        case .broker(let broker):
            addBroker(broker, to: handle)
        }
    }

    /// Registers a broker source, including selectors, on the verifier `handle`.
    func addBroker(_ broker: VerificationOptions.Broker, to handle: OpaquePointer) {
        withCStringArray(broker.providerTags) { providerTags, providerTagsLength in
            withCStringArray(broker.consumerVersionSelectors) { selectors, selectorsLength in
                withCStringArray(broker.consumerVersionTags) { versionTags, versionTagsLength in
                    _ = pactffi_verifier_broker_source_with_selectors(
                        handle,
                        broker.url.absoluteString.cString(using: .utf8),
                        broker.authentication?.username?.cString(using: .utf8),
                        broker.authentication?.password?.cString(using: .utf8),
                        broker.authentication?.token?.cString(using: .utf8),
                        broker.enablePending ? 1 : 0,
                        broker.includeWIPPactsSince?.iso8601Short.cString(using: .utf8),
                        providerTags,
                        providerTagsLength,
                        broker.providerBranch?.cString(using: .utf8),
                        selectors,
                        selectorsLength,
                        versionTags,
                        versionTagsLength
                    )
                }
            }
        }
    }
}

// MARK: - Helpers

private extension VerificationOptions.Authentication {

    var username: String? {
        guard case let .basic(username, _) = self else { return nil }
        return username
    }

    var password: String? {
        guard case let .basic(_, password) = self else { return nil }
        return password
    }

    var token: String? {
        guard case let .token(token) = self else { return nil }
        return token
    }
}

private extension Date {

    /// Date as a short ISO8601 string (eg `"2026-07-20"`), as the broker WIP filter expects.
    var iso8601Short: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}

/// Invokes `body` with a C array of C strings (`const char *const *` + length) valid only for the
/// duration of the call. Passing an empty array yields a null pointer and a length of `0`.
private func withCStringArray<R>(
    _ values: [String],
    _ body: (UnsafePointer<UnsafePointer<CChar>?>?, UInt16) -> R
) -> R {
    var cStrings: [UnsafePointer<CChar>?] = values.map { UnsafePointer(strdup($0)) }
    defer { cStrings.forEach { free(UnsafeMutablePointer(mutating: $0)) } }
    return cStrings.withUnsafeBufferPointer { buffer in
        body(buffer.baseAddress, UInt16(values.count))
    }
}
