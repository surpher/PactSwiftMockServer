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

import Foundation
import XCTest
import PactSwiftMockServer

final class PactBuilderTests: XCTestCase {

    private let consumer = "Test_Consumer"
    private let provider = "Test_Provider"
    
    private let session = URLSession(configuration: .ephemeral)
    
    var builder: PactBuilder!
    
    private var pactDirectory: String {
        NSTemporaryDirectory().appending("pacts/")
    }
    
    private var pactFilePath: String {
        pactDirectory.appending("\(consumer)-\(provider).json")
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        guard builder == nil else {
            return
        }
        
        let pact = try Pact(consumer: consumer, provider: provider)
            .withSpecification(.v4)
            .withMetadata(namespace: "events", name: "meta-name1", value: "meta-value1")
            .withMetadata(namespace: "events", name: "meta-name2", value: "meta-value2")
        
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
                try request
                    .queryParam(name: "something", value: "orOther")
                    .queryParam(name: "limit", value: Match.decimal(100))
                    .queryParam(name: "includeOthers", value: Match.bool(false))
                
            }
            .willRespond(with: 200) { response in
                try response.htmlBody()
            }
        
        try await builder.verify { ctx in
            var components = try XCTUnwrap(URLComponents(url: ctx.mockServerURL, resolvingAgainstBaseURL: false))
            components.path = "/events"
            components.queryItems = [
                URLQueryItem(name: "something", value: "orOther"),
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "includeOthers", value: "false")
            ]
            
            let (data, response) = try await session.data(from: try XCTUnwrap(components.url))
            
            let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
            XCTAssertEqual(httpResponse.statusCode, 200)
            XCTAssertEqual(httpResponse.value(forHTTPHeaderField: "Content-Type"), "text/html")
            XCTAssertTrue(data.isEmpty)
        }
        
        // TODO: load file and look for interaction
    }

    func testCreateEvent() async throws {
        try builder
            .uponReceiving("a request to create an event with no authorization")
            .given("There are events")
            .withRequest(method: .POST, path: "/events") { request in
                try request.header("Accept", value: "application/json")
            }
            .willRespond(with: 201) { response in
                try response.htmlBody("OK")
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
            XCTAssertEqual(httpResponse.value(forHTTPHeaderField: "Content-Type"), "text/html")
            XCTAssertEqual(data, "OK".data(using: .utf8))
        }
        
        // TODO: load file and look for interaction
    }
    
    func testGetEvent() async throws {
        try builder
            .uponReceiving("a request for an event with no authorization")
            .given("There are events")
            .withRequest(method: .GET, regex: Match.regex(#"/events/\d+"#, example: "/events/100")) { request in
                try request
                    .header("Accept", value: "application/json")
                    .header("X-Version", value: Match.integer(1))
            }
            .willRespond(with: 200) { response in
                try response.htmlBody("OK")
            }
        
        try await builder.verify { ctx in
            var components = try XCTUnwrap(URLComponents(url: ctx.mockServerURL, resolvingAgainstBaseURL: false))
            components.path = "/events/23"
            
            var request = URLRequest(url: try XCTUnwrap(components.url))
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("1", forHTTPHeaderField: "X-Version")
                        
            let (data, response) = try await session.data(for: request)
            
            let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
            XCTAssertEqual(httpResponse.statusCode, 200)
            XCTAssertEqual(httpResponse.value(forHTTPHeaderField: "Content-Type"), "text/html")
            XCTAssertEqual(data, "OK".data(using: .utf8))
        }
        
        // TODO: load file and look for interaction
    }
    
}
