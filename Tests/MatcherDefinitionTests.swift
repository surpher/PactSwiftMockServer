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

class MatcherDefinitionTests: XCTestCase {
    
    func testParser() throws {
        
        let expressions: [String: (MatcherDefinition.ValueType, String?, String?, MatcherDefinition.RuleResult?)] = [
            "matching(equalTo, 'Example')": (.string, "Example", nil, .matchingRule(.equality, "")),
            "matching(type, 'Example value')": (.string, "Example value", nil, .matchingRule(.type, "")),
            "matching(number, 100.09)": (.number, "100.09", nil, .matchingRule(.number, "")),
            "matching(integer, 100)": (.integer, "100", nil, .matchingRule(.integer, "")),
            "matching(decimal, 100.01)": (.decimal, "100.01", nil, .matchingRule(.decimal, "")),
            "matching(datetime, 'yyyy-MM-dd HH:mm:ssZZZZZ', '2020-05-21 16:44:32+10:00')": (.string, "2020-05-21 16:44:32+10:00", #"{"format":"yyyy-MM-dd HH:mm:ssZZZZZ","type":"DateTime"}"#, .matchingRule(.timestamp, "yyyy-MM-dd HH:mm:ssZZZZZ")),
            "matching(date, 'yyyy-MM-dd', '2002-12-11')": (.string, "2002-12-11", #"{"format":"yyyy-MM-dd","type":"Date"}"#, .matchingRule(.date, "yyyy-MM-dd")),
            "matching(time, 'HH:mm', '22:04')": (.string, "22:04", #"{"format":"HH:mm","type":"Time"}"#, .matchingRule(.time, "HH:mm")),
            "matching(regex, '\\w{3}\\d+', 'abc123')": (.string, "abc123", nil, .matchingRule(.regex, "\\w{3}\\d+")),
            "matching(include, 'testing')": (.string, "testing", nil, .matchingRule(.include, "testing")),
            "matching(boolean, true)": (.boolean, "true", nil, .matchingRule(.boolean, "")),
            "matching(semver, '1.0.0')": (.string, "1.0.0", nil, .matchingRule(.semver, "")),
            "matching(contentType, 'application/xml', '<?xml?><test/>')": (.unknown, "<?xml?><test/>", nil, .matchingRule(.contentType, "application/xml")),
            "eachValue(matching($'person'))": (.unknown, "", nil, .matchingRule(.eachValue, "")),
            "eachKey(matching(regex, '\\$(\\.\\w+)+', '$.test.one'))": (.unknown, "", nil, .matchingRule(.eachKey, "")),
            "notEmpty('test')": (.string, "test", nil, .matchingRule(.notEmpty, "")),
            "notEmpty(1)": (.integer, "1", nil, .matchingRule(.notEmpty, "")),
            "notEmpty(1.1)": (.decimal, "1.1", nil, .matchingRule(.notEmpty, "")),
            "$'result'": (.string, "$'result'", nil, nil)
        ]
        
        for expression in expressions.keys {
            let sut = try MatcherDefinition(expression)
                        
            XCTAssertEqual(sut.valueType, expressions[expression]?.0)
            XCTAssertEqual(sut.value, expressions[expression]?.1)
            XCTAssertEqual(sut.generatorJSON, expressions[expression]?.2)
            
            XCTAssertEqual(sut.results.count, expressions[expression]?.3 == nil ? 0 : 1)
            XCTAssertEqual(sut.results.first, expressions[expression]?.3)
        }
    }
    
}
