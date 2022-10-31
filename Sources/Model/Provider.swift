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

public struct Provider {

	public struct Info {
		let name: String?
		let scheme: TransferProtocol
		let host: String?
		let port: UInt16
		let path: String?

		public init(name: String? = nil, scheme: TransferProtocol = .secure, host: String? = nil, port: UInt16, path: String? = nil) {
			self.name = name
			self.scheme = scheme
			self.host = host
			self.port = port
			self.path = path
		}
	}

	public struct Filter {
		let description: String
		let state: String
		let noState: Bool

		/// Filters used when verifying a provider
		///
		/// All string fields must contain valid UTF-8 characters. Invalid UTF-8 characters will be replaced with U+FFFD replacement character.
		public init(description: String = "", state: String = "", noState: Bool = false) {
			self.description = description
			self.state = state
			self.noState = noState
		}
	}

	public struct State {
		let urlString: String
		let teardown: Bool
		let body: Bool

		public init(urlString: String, teardown: Bool = false, body: Bool = false) {
			self.urlString = urlString
			self.teardown = teardown
			self.body = body
		}
	}

	// MARK: -

	let tags: [String]
	let branch: String

}
