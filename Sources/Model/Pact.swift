//
//  Created by Oliver Jones on 12/12/2022.
//  Copyright © 2022 Oliver Jones. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

#if SWIFT_PACKAGE
import PactMockServer
#endif

public final class Pact {

	public enum Specification {
		case v1, v1_1, v2, v3, v4
	}

	public enum Error {
		case canNotBeModified

		/// The Pact file could not be written.  The associated error codes:
		///
		/// - 1 - The function panicked.
		/// - 2 - The pact file was not able to be written.
		/// - 3 - The pact for the given handle was not found.
		case canNotWritePact(Int32)
	}

	public var version: String {
		ffiProvider.version
	}

	public let consumer: String
	public let provider: String

	internal let handle: PactHandle

	private let ffiProvider: PactFFIProviding

	public var filename: String {
		"\(consumer)-\(provider).json"
	}

	public init(consumer: String, provider: String) {
		self.consumer = consumer
		self.provider = provider
		self.ffiProvider = DefaultPactFFIProvider()

		self.handle = ffiProvider.newPact(consumer: consumer, provider: provider)
	}

	deinit {
		ffiProvider.freePactHandle(handle)
	}

	/// Sets the specification version for a given Pact model.
	///
	/// Throws ``Error/canNotBeModified`` if Pact can’t be modified (i.e. the mock server for it has already started).
	public func withSpecification(_ specification: Specification) throws -> Self {
		try ffiProvider.withSpecification(handle: handle, version: specification)

		return self
	}

	/// Sets the additional metadata on the Pact file.
	///
	/// Common uses are to add the client library details such as the name and version.
	///
	/// - Throws: ``Error/canNotBeModified`` if Pact can’t be modified (i.e. the mock server for it has already started).
	/// - Parameters:
	///   - namespace: The top level metadata key to set the name/values on. Each namespace must be unique (or it will be overwritten).
	///   - name: A key name to set.
	///   - value: A value to set.
	public func withMetadata(namespace: String, name: String, value: String) throws -> Self {
		try ffiProvider.withMetadata(handle: handle, namespace: namespace, key: name, value: value)
		return self
	}

	/// Create a new `Interaction`.
	///
	/// - parameter description - The interaction description. It needs to be unique for each interaction.
	internal func uponReceiving(_ description: String) -> Interaction {
		Interaction(pactHandle: handle, description: description)
	}

	/// Write out the pact file.
	///
	/// This function should be called if all the consumer tests have passed.
	///
	/// - Parameters:
	///   - directory: The directory to write the file to. When `nil` the current working directory is used.
	///   - overwrite: When `true`, the file will be overwritten with the contents of the current pact. Otherwise, it will be merged with any existing pact file.
	///
	public func writePactFile(directory: String? = nil, overwrite: Bool = false) throws {
		let writeDirectory = directory ?? FileManager.default.currentDirectoryPath
		Logging.log(.debug, message: "Attempting to write pact to file in directory '\(writeDirectory)'")
		try ffiProvider.writePactFile(handle: handle, to: writeDirectory, overwrite: overwrite)
		Logging.log(.info, message: "Wrote pact to '\(writeDirectory)/\(filename)'")
	}

}

extension Pact.Error: LocalizedError {

	public var failureReason: String? {
		switch self {
		case .canNotBeModified:
			return NSLocalizedString("Pact can not be modified", comment: "A error failure reason when a Pact can not be modified")
		case .canNotWritePact(let code):
			return String.localizedStringWithFormat(
				NSLocalizedString(
					"Can not write to Pact file (error code: %d)",
					comment: "Format for error failure reason when can't write to Pact file"
				),
				code
			)
		}
	}
}
