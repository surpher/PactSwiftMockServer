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

public struct Consumer {

	let versionSelectors: [VersionSelector]
	let tags: [String]

	var versionSelectorsAsJSONStrings: [String] {
		do {
			let encodedVersionSelectors = try versionSelectors.compactMap {
				let encodedSelector = try JSONEncoder().encode($0)
				return String(data: encodedSelector, encoding: .utf8)
			}
			return encodedVersionSelectors
		} catch {
			Logger.log(message: "Failed to encode VersionSelectors into JSON data! Error: \(error.localizedDescription)")
			return []
		}
	}

	public init(versionSelectors: [VersionSelector]) {
		self.versionSelectors = versionSelectors
		self.tags = []
	}

	public init(tags: [String]) {
		self.tags = tags
		self.versionSelectors = []
	}

}
