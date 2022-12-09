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

import XCTest

@testable import PactSwiftMockServer

class MockServerTests: XCTestCase {

    private func makeMockServer(secure: Bool = false) -> MockServer {
        return MockServer(transferProtocol: secure ? .secure : .standard)
    }

	// MARK: - Tests

	func testMockServer_Initializes() async throws {
		let port = try await makeMockServer().setup(pact: "{\"foo\":\"bar\"}".data(using: .utf8)!)
        XCTAssertGreaterThan(port, 1200)
	}

	func testMockServer_SetsBaseURL() async throws {
        let mockServer = makeMockServer()
        let port = try await mockServer.setup(pact: "{\"foo\":\"bar\", \"baz\":\"[\\\"key\\\":\\\"value\\\"]\"}".data(using: .utf8)!)
        let baseUrl = await mockServer.baseUrl
		XCTAssertEqual(baseUrl, "http://127.0.0.1:\(port)")
	}

	func testMockServer_SetsBaseSSLURL() async throws {
        let mockServer = makeMockServer(secure: true)
		let port = try await mockServer.setup(pact: "{\"foo\":\"bar\"}".data(using: .utf8)!)
        let baseUrl = await mockServer.baseUrl
        XCTAssertEqual(baseUrl, "https://127.0.0.1:\(port)")
	}

	func testMockServer_Fails_WithInvalidPactJSON() async throws {
        let mockServer = makeMockServer()
        do {
            _ = try await mockServer.setup(pact: "{\"foo\":bar\"}".data(using: .utf8)!)
            XCTFail("Expected Pact Mock Server to fail")
        } catch let error as MockServerError {
            XCTAssertEqual(error, MockServerError.invalidPactJSON)
        } catch {
            XCTFail("Unexpected error type \(type(of: error))")
        }
	}

	func testMocServer_SanityTestTLS() async throws {
        let isSecure = true
        let testUrlSessionDelegate = TestURLSessionDelegate(isHTTPS: isSecure)
        let mockServer = makeMockServer(secure: isSecure)

        _ = try await mockServer.setup(pact: .pactSpecV3)
        
        let session = URLSession(configuration: .ephemeral, delegate: testUrlSessionDelegate, delegateQueue: .main)
        let (data, _) = try await session.data(from: URL(string: "\(mockServer.baseUrl)/users")!)
        
        let testUsers = try JSONDecoder().decode([MockServerTestUser].self, from: data)
        XCTAssertEqual(testUsers.count, 3)
        XCTAssertTrue(testUsers.contains(where: { $0.name == "ZSAICmTmiwgFFInuEuiK" }))

        _ = try await mockServer.finalize(pact: .pactSpecV3)
	}

	func testMockServer_SanityTestHTTP() async throws {
        let testUrlSessionDelegate = TestURLSessionDelegate()
        let mockServer = makeMockServer()

        _ = try await mockServer.setup(pact: .pactSpecV3)

        let session = URLSession(configuration: .ephemeral, delegate: testUrlSessionDelegate, delegateQueue: .main)
        let (data, _) = try await session.data(from: URL(string: "\(mockServer.baseUrl)/users")!)
        
        let testUsers = try JSONDecoder().decode([MockServerTestUser].self, from: data)
        XCTAssertEqual(testUsers.count, 3)
        XCTAssertTrue(testUsers.contains(where: { $0.name == "ZSAICmTmiwgFFInuEuiK" }))
	
        _ = try await mockServer.finalize(pact: .pactSpecV3)
	}

	func testGeneratesStringFromRegex() {
		XCTAssertEqual(MockServer.generate_value(regex: #"\d{4}"#)?.count, 4)

		let generatedString = MockServer.generate_value(regex: #"\d{4}-\d{2}:\d{2}abc"#)
		XCTAssertEqual(generatedString?.count, 13)
		XCTAssertEqual(generatedString?.suffix(3), "abc")
		XCTAssertNil(generatedString?.prefix(4).rangeOfCharacter(from: CharacterSet.decimalDigits.inverted), "Expected first four characters to be digits")
		XCTAssertEqual(generatedString?.indexOf(char: "-"), 4)
		XCTAssertEqual(generatedString?.indexOf(char: ":"), 7)
	}

	func testGeneratesDateTimeStringInExpectedFormat() throws {
		let dateFormat = "YYYY-MM-dd"
		let generatedDatetime = try XCTUnwrap(MockServer.generate_date(format: dateFormat))

		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = dateFormat
		let resultDate = dateFormatter.date(from: generatedDatetime)

		XCTAssertNotNil(resultDate)
	}

}
    
private struct MockServerTestUser: Decodable {
    let dob: String
    let id: Int
    let name: String
}

private class TestURLSessionDelegate: NSObject, URLSessionDelegate {
    
    var isHTTPS: Bool
    
    init(isHTTPS: Bool = false) {
        self.isHTTPS = isHTTPS
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard
            isHTTPS,
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            (challenge.protectionSpace.host.contains("127.0.0.1") || challenge.protectionSpace.host.contains("0.0.0.0") || challenge.protectionSpace.host.contains("localhost")),
            let serverTrust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }
}

private extension Data {
    
    // Pact taken from: https://github.com/pact-foundation/pact-specification/tree/version-3
    // JSON formatted using: https://jsonformatter.curiousconcept.com (settings: compact, RFC 8259)
    static var pactSpecV3: Self {
        """
        {"provider":{"name":"sanity_test_provider"},"consumer":{"name":"sanity_test_consumer"},"metadata":{"pactSpecification":{"version":"3.0.0"},"pact-swift":{"version":"0.0.1"}},"interactions":[{"description":"swift test interaction with a DSL array body","request":{"method":"GET","path":"/users"},"response":{"status":200,"headers":{"Content-Type":"application/json; charset=UTF-8"},"body":[{"dob":"2016-07-19","id":1943791933,"name":"ZSAICmTmiwgFFInuEuiK"},{"dob":"2016-07-19","id":1943791933,"name":"ZSAICmTmiwgFFInuEuiK"},{"dob":"2016-07-19","id":1943791933,"name":"ZSAICmTmiwgFFInuEuiK"}],"matchingRules":{"body": {"$[2].name":{"matchers":[{"match":"type"}]},"$[0].id":{"matchers":[{"match":"type"}]},"$[1].id":{"matchers":[{"match":"type"}]},"$[2].id":{"matchers":[{"match":"type"}]},"$[1].name":{"matchers":[{"match":"type"}]},"$[0].name":{"matchers":[{"match":"type"}]},"$[0].dob":{"matchers":[{"date":"yyyy-MM-dd"}]}}}}}]}
        """.data(using: .utf8)!
    }

}

private extension String {
    
	func indexOf(char: Character) -> Int? {
		 firstIndex(of: char)?.utf16Offset(in: self)
	}

}
