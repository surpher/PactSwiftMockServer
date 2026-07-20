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

    func testVerificationFailsForMissingPactDirectory() {
        let options = VerificationOptions(
            provider: .init(port: 1234),
            sources: [.directory("../NonExistingDir")]
        )

        let result = testSubject.verifyProvider(options: options)

        XCTAssertEqual(result, .failure(.verificationFailed))
    }

    func testVerificationFailsForMissingPactFile() {
        let options = VerificationOptions(
            provider: .init(port: 1234),
            sources: [.file("../Non/Existing/invalid/path.json")]
        )

        let result = testSubject.verifyProvider(options: options)

        XCTAssertEqual(result, .failure(.verificationFailed))
    }

}
