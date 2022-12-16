//
//  Created by Oliver Jones on 16/12/2022.
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

import XCTest
@testable import PactSwiftMockServer

class MatcherTests: XCTestCase {
 
    func testMatcherEncodable() throws {
        
        let matcher: AnyMatcher = .eachLike(
            [
                "id": .likeInteger(1),
                "name": .like("A Name")
            ],
            min: 1
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        
        let data = try encoder.encode(matcher)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        
        XCTAssertEqual(
            json,
            #"""
            {
              "min" : 1,
              "pact:matcher:type" : "type",
              "value" : {
                "id" : {
                  "pact:matcher:type" : "integer",
                  "value" : 1
                },
                "name" : {
                  "pact:matcher:type" : "type",
                  "value" : "A Name"
                }
              }
            }
            """#
        )
        
    }
    
}
