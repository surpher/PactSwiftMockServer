//
//  Created by Marko Justinek on 31/10/2022.
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

/// The Consumer Version Selector configuring which pacts the provider verifies.
///
/// See [https://docs.pact.io/pact_broker/advanced_topics/consumer_version_selectors](https://docs.pact.io/pact_broker/advanced_topics/consumer_version_selectors) for more.
///
public struct VersionSelector: Encodable {

	let mainBranch: Bool?
	let tag: String?
	let fallbackTag: String?
	let latest: Bool?
	let consumer: String?
	let deployed: Bool?
	let released: Bool?
	let deployedOrReleased: Bool?
	let branch: String?
	let fallbackBranch: String?
	let matchingBranch: Bool?
	let environment: String?

	/// The Consumer Version Selector configuring which pacts the provider verifies.
	///
	/// See [https://docs.pact.io/pact_broker/advanced_topics/consumer_version_selectors](https://docs.pact.io/pact_broker/advanced_topics/consumer_version_selectors) for more.
	///
	/// - warning: Note that this is a very unsafe initializer available for this type.
	/// To avoid unexpected behaviour **do read** through [Consumer Version Selectors](https://docs.pact.io/pact_broker/advanced_topics/consumer_version_selectors)
	/// document to learn how to set the values to use Consumer Version Selectors effectively.
	///
	public init?(
		mainBranch: Bool? = nil,
		tag: String? = nil,
		fallbackTag: String? = nil,
		latest: Bool? = nil,
		consumer: String? = nil,
		deployed: Bool? = nil,
		released: Bool? = nil,
		deployedOrReleased: Bool? = nil,
		branch: String? = nil,
		fallbackBranch: String? = nil,
		matchingBranch: Bool? = nil,
		environment: String? = nil
	) {
		self.mainBranch = mainBranch
		self.tag = tag
		self.fallbackTag = fallbackTag
		self.latest = latest
		self.consumer = consumer
		self.deployed = deployed
		self.released = released
		self.deployedOrReleased = deployedOrReleased
		self.branch = branch
		self.fallbackBranch = fallbackBranch
		self.matchingBranch = matchingBranch
		self.environment = environment
	}

 }
