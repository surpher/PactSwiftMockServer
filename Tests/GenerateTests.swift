//
//  Created by Oliver Jones on 15/12/2022.
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

@testable import PactSwiftMockServer

import XCTest

class GenerateTests: XCTestCase {

	private let generatedStringCount = 13

	func testGeneratesStringFromRegex() {
		XCTAssertEqual(Generate.value(regex: #"\d{4}"#)?.count, 4)
		
		let generatedString = Generate.value(regex: #"\d{4}-\d{2}:\d{2}abc"#)
		XCTAssertEqual(generatedString?.count, generatedStringCount)
		XCTAssertEqual(generatedString?.suffix(3), "abc")
		XCTAssertNil(generatedString?.prefix(4).rangeOfCharacter(from: CharacterSet.decimalDigits.inverted), "Expected first four characters to be digits")
		XCTAssertEqual(generatedString?.indexOf(char: "-"), 4)
		XCTAssertEqual(generatedString?.indexOf(char: ":"), 7)
	}
	
	func testGeneratesDateTimeStringInExpectedFormat() throws {
		let dateFormat = "YYYY-MM-dd"
		let generatedDatetime = try XCTUnwrap(Generate.date(format: dateFormat))
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = dateFormat
		let resultDate = dateFormatter.date(from: generatedDatetime)
		
		XCTAssertNotNil(resultDate)
	}
	
}

private extension String {
	
	func indexOf(char: Character) -> Int? {
		firstIndex(of: char)?.utf16Offset(in: self)
	}
	
}
