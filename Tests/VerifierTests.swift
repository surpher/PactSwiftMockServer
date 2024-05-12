//
//  Created by Marko Justinek on 21/8/21.
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

import XCTest

#if os(Linux)
    @testable import PactSwiftMockServerLinux
#else
    @testable import PactSwiftMockServer
#endif
class VerifierTests: XCTestCase {

	// MARK: - Properties

	private var testSubject: Verifier!

	// MARK: - Lifecycle

	override func setUpWithError() throws {
		try super.setUpWithError()

		testSubject = Verifier()
	}

	override func tearDownWithError() throws {
		testSubject = nil

		try super.tearDownWithError()
	}

	// MARK: - Tests

	func testVerificationFails() {
		let result = testSubject.verifyProvider(options: validArgs)
		XCTAssertEqual(result, .failure(.verificationFailed))
	}

	func testInvalidArguments() {
		let result = testSubject.verifyProvider(options: invalidArgs)
		XCTAssertEqual(result, .failure(.invalidArguments))
	}

}

private extension VerifierTests {

	var validArgs: String {
		"--port\n1234\n--dir\n../NonExistingDir"
	}

	var invalidArgs: String {
		"--port\n1234\n--dir\n../Non\n/Existing/invalid/\npath"
	}

}
