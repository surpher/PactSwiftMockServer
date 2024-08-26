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

#if SWIFT_PACKAGE
import PactMockServer
#endif

public enum Generate {
	/// Generates an example string based on provided regex pattern
	///
	/// Only supports basic regex patterns.
	///
	/// - Parameters:
	///   - regex: The pattern to use
	///
	public static func value(regex: String) -> String? {
		let result = pactffi_generate_regex_value(regex.cString(using: .utf8))
		guard result.tag == StringResult_Ok, let stringPointer = result.ok else {
			return nil
		}
		defer {
			pactffi_string_delete(stringPointer)
		}

		return String(cString: stringPointer)
	}

	/// Generates an example datetime string based on provided format
	///
	/// Returns `nil` if the provided format is invalid
	///
	/// - Parameters:
	///   - format: The format of date to generate
	///
	public static func date(format: String) -> String? {
		let result = pactffi_generate_datetime_string(format.cString(using: .utf8))
		guard result.tag == StringResult_Ok, let stringPointer = result.ok else {
			return nil
		}
		defer {
			pactffi_string_delete(stringPointer)
		}

		return String(cString: stringPointer)
	}
}
