//
//  Created by Marko Justinek on 21/8/21.
//  Copyright © 2021 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import XCTest

@testable import PactSwiftMockServer

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
