//
//  Created by Oliver Jones on 14/12/2022.
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

final class PactBuilderTests: XCTestCase {

    private let consumer = "Test_Consumer"
    private let provider = "Test_Provider"
    
    private let session = URLSession(configuration: .ephemeral)
    
    var builder: PactBuilder!
    
    private var pactDirectory: String {
        NSTemporaryDirectory().appending("pacts/")
    }
        
    override func setUpWithError() throws {
        try super.setUpWithError()

        guard builder == nil else {
            return
        }
        
        let pact = try Pact(consumer: consumer, provider: provider)
            .withSpecification(.v4)
            .withMetadata(namespace: "namespace1", name: "name1", value: "value1")
            .withMetadata(namespace: "namespace2", name: "name2", value: "value2")
        
        let config = PactBuilder.Config(pactDirectory: pactDirectory)
        builder = PactBuilder(pact: pact, config: config)
    }
    
    func testPactVersion() throws {
        XCTAssertEqual(Pact.version, "0.3.15")
    }
    
    func testGetEvents() async throws {
        try builder
            .uponReceiving("a request to retrieve all events with no authorization")
            .given("There are events")
            .withRequest(path: "/events") { request in
                try request.queryParam(name: "something", values: ["orOther"])
            }
            .willRespond(with: 200) { response in
                try response.body("", contentType: "text/plain")
            }
        
        try await builder.verify { ctx in
            var components = try XCTUnwrap(URLComponents(url: ctx.mockServerURL, resolvingAgainstBaseURL: false))
            components.path = "/events"
            components.queryItems = [
                URLQueryItem(name: "something", value: "orOther"),
            ]
            
            let (data, response) = try await session.data(from: try XCTUnwrap(components.url))
            
            let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
            XCTAssertEqual(httpResponse.statusCode, 200)
            XCTAssertEqual(httpResponse.value(forHTTPHeaderField: "Content-Type"), "text/plain")
            XCTAssertTrue(data.isEmpty)
        }
    }

    func testCreateEvent() async throws {
        try builder
            .uponReceiving("a request to create an event with no authorization")
            .given("There are events")
            .withRequest(method: .POST, path: "/events") { request in
                try request.header("Accept", values: ["application/json"])
            }
            .willRespond(with: 201) { response in
                try response.body("OK", contentType: "text/plain")
            }
        
        try await builder.verify { ctx in
            var components = try XCTUnwrap(URLComponents(url: ctx.mockServerURL, resolvingAgainstBaseURL: false))
            components.path = "/events"
            
            var request = URLRequest(url: try XCTUnwrap(components.url))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
                        
            let (data, response) = try await session.data(for: request)
            
            let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
            XCTAssertEqual(httpResponse.statusCode, 201)
            XCTAssertEqual(httpResponse.value(forHTTPHeaderField: "Content-Type"), "text/plain")
            XCTAssertEqual(data, "OK".data(using: .utf8))
        }
    }
}


