//
//  Created by Marko Justinek on 17/12/2024.
//  Copyright © 2024 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

@testable import PactSwiftMockServer

import XCTest

final class PactSwiftMockServerTests: XCTestCase {

    private let prefix = "Provider Verification Error:"

    func testInit() {
        XCTAssertEqual(
            ProviderVerificationError.init(code: 1),
            .verificationFailed
        )

        XCTAssertEqual(
            ProviderVerificationError.init(code: 2),
            .nullPointer
        )

        XCTAssertEqual(
            ProviderVerificationError.init(code: 3),
            .methodPanicked
        )

        XCTAssertEqual(
            ProviderVerificationError.init(code: 4),
            .invalidArguments
        )

        [0, 5, 6, 7, 8, 9, 10, 999, 999_999].forEach {
            XCTAssertEqual(
                ProviderVerificationError.init(code: $0),
                .unknown
            )
        }
    }

    func testErrorDescription() {
        XCTAssertEqual(
            ProviderVerificationError.verificationFailed.description,
            "\(prefix) The verification process failed, see output for errors."
        )

        XCTAssertEqual(
            ProviderVerificationError.nullPointer.description,
            "\(prefix) A null pointer was received."
        )

        XCTAssertEqual(
            ProviderVerificationError.methodPanicked.description,
            "\(prefix) The method panicked."
        )

        XCTAssertEqual(
            ProviderVerificationError.invalidArguments.description,
            "\(prefix) Invalid arguments were provided to the verification process."
        )

        XCTAssertEqual(
            ProviderVerificationError.usageError("Foo Bar Baz").description,
            "\(prefix) Foo Bar Baz"
        )

        XCTAssertEqual(
            ProviderVerificationError.unknown.description,
            "\(prefix) Unknown error!"
        )
    }
}
