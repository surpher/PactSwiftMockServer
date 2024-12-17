//
//  Created by Oliver Jones on 15/12/2022.
//  Copyright © 2022 Oliver Jones. All rights reserved.
//
//  See LICENSE file for licensing information.
//

@testable import PactSwiftMockServer

import XCTest

class GenerateTests: XCTestCase {

	private let generatedStringCount = 13

	func testGeneratesStringFromRegex() {
		XCTAssertEqual(Generate.string(regex: #"\d{4}"#)?.count, 4)

		let generatedString = Generate.string(regex: #"\d{4}-\d{2}:\d{2}abc"#)
		XCTAssertEqual(generatedString?.count, generatedStringCount)
		XCTAssertEqual(generatedString?.suffix(3), "abc")
		XCTAssertNil(generatedString?.prefix(4).rangeOfCharacter(from: CharacterSet.decimalDigits.inverted), "Expected first four characters to be digits")
		XCTAssertEqual(generatedString?.indexOf(char: "-"), 4)
		XCTAssertEqual(generatedString?.indexOf(char: ":"), 7)
	}

	func testNilWithInvalidRegex() {
		let generatedString = Generate.string(regex: #"[a-Z"#)
		XCTAssertNil(generatedString)
	}

	func testGeneratesDateTimeStringInExpectedFormat() throws {
		let dateFormat = "YYYY-MM-dd"
		let generatedDatetime = try XCTUnwrap(Generate.date(format: dateFormat))
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = dateFormat
		let resultDate = dateFormatter.date(from: generatedDatetime)
		
		XCTAssertNotNil(resultDate)
	}

	func testNilWhenInvalidDateTimeFormat() {
		let invalidFormat = Generate.date(format: "AA-BB-MMM-YYYY -dd")
		XCTAssertNil(invalidFormat)
	}
}

private extension String {
	
	func indexOf(char: Character) -> Int? {
		firstIndex(of: char)?.utf16Offset(in: self)
	}
}
