//
//  Created by Marko Justinek on 12/4/20.
//  Copyright © 2020 Marko Justinek. All rights reserved.
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

@testable import PactSwiftMockServer

import XCTest

class MockServerTests: XCTestCase {

	@MainActor
	class override func setUp() {
		super.setUp()
		try! Logging.initialize()
	}

	func testMockServer_Initializes() throws {
		let pact = Pact(consumer: "Consumer", provider: "Provider")
		let server = try MockServer(pact: pact, transferProtocol: .standard)
		XCTAssertGreaterThan(server.port, 0)
	}
	
	func testMockServer_SetsBaseURL() throws {
		let pact = Pact(consumer: "Consumer", provider: "Provider")
		let server = try MockServer(pact: pact, transferProtocol: .standard)
		XCTAssertEqual(server.baseUrl, try XCTUnwrap(URL(string: "http://127.0.0.1:\(server.port)")))
	}
	
	func testMockServer_SetsBaseSSLURL() throws {
		let pact = Pact(consumer: "Consumer", provider: "Provider")
		let server = try MockServer(pact: pact, transferProtocol: .secure)
		XCTAssertEqual(server.baseUrl, try XCTUnwrap(URL(string: "https://127.0.0.1:\(server.port)")))
	}
	
	func testMockServer_GetTLSCert() throws {
		let pact = Pact(consumer: "Consumer", provider: "Provider")
		let server = try MockServer(pact: pact, transferProtocol: .secure)
		XCTAssertNotNil(server.tlsCACertificate)
	}
}
