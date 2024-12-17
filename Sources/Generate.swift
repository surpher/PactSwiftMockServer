//
//  Created by Oliver Jones on 15/12/2022.
//  Copyright © 2022 Oliver Jones. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

#if SWIFT_PACKAGE
import PactMockServer
#endif

public enum Generate {

	/// Generates an example string based on provided regex pattern
	///
	/// Only supports basic regex patterns.
	///
	/// - Parameters:
	///   - regex: The pattern to use.
	///
	/// - Returns: `nil` if the provided regex pattern is invalid.
	///
	public static func string(regex: String) -> String? {
		generateString(from: regex)
	}

	/// Generates an example date-time string based on provided format
	///
	/// - Parameters:
	///   - format: The format of date to generate
	///
	/// - Returns: `nil` if the provided format is invalid.
	///
	public static func date(format: String) -> String? {
		generateDate(format: format)
	}
}

// MARK: - Internal

extension Generate {

	static func generateString(from regex: String, ffiProvider: PactFFIProviding = DefaultPactFFIProvider()) -> String? {
		ffiProvider.generateString(regex: regex)
	}

	static func generateDate(format: String, ffiProvider: PactFFIProviding = DefaultPactFFIProvider()) -> String? {
		ffiProvider.generateDateTimeString(format: format)
	}
}
