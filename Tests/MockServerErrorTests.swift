//
//  Created by Marko Justinek on 25/5/20.
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

import XCTest
import PactSwiftMockServer

class MockServerErrorTests: XCTestCase {

    public enum Error: Equatable {
        case unknown(Int32)
        case invalidHandle
        case invalidPactJSON
        case unableToStart
        case panic
        case invalidAddress
        case tlsConfigFailure
    }
    
	func testErrorCodes() {
        XCTAssertEqual(MockServer.Error.invalidHandle.rawValue, -1)
        XCTAssertEqual(MockServer.Error.invalidPactJSON.rawValue, -2)
        XCTAssertEqual(MockServer.Error.unableToStart.rawValue, -3)
        XCTAssertEqual(MockServer.Error.panicked.rawValue, -4)
        XCTAssertEqual(MockServer.Error.invalidAddress.rawValue, -5)
        XCTAssertEqual(MockServer.Error.tlsConfigFailure.rawValue, -6)
        XCTAssertEqual(MockServer.Error.unknown(-10).rawValue, -10)
	}
    
    func testRawRepresentable() {
        XCTAssertEqual(MockServer.Error(rawValue: -1), .invalidHandle)
        XCTAssertEqual(MockServer.Error(rawValue: -2), .invalidPactJSON)
        XCTAssertEqual(MockServer.Error(rawValue: -3), .unableToStart)
        XCTAssertEqual(MockServer.Error(rawValue: -4), .panicked)
        XCTAssertEqual(MockServer.Error(rawValue: -5), .invalidAddress)
        XCTAssertEqual(MockServer.Error(rawValue: -6), .tlsConfigFailure)
        XCTAssertEqual(MockServer.Error(rawValue: -10), .unknown(-10))
    }
}
