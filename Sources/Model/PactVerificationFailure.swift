//
//  Created by Marko Justinek on 27/4/20.
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

import Foundation

public struct PactVerificationFailure {
	public let type: FailureType
	public let method: String
	public let path: String
	public let request: Request?
	public let mismatches: [Mismatch]

	public enum FailureType {
		case missing
		case requestNotFound
		case requestMismatch
		case mockServerParsingFail
		case unknown(String)
	}

	public struct Request {
		let method: String
		let path: String
		let headers: [String: String]?
	}

	public struct Mismatch {
		public let type: MismatchType
		public let expected: Expected
		public let actual: Actual?
		public let parameter: String?
		public let mismatch: String?

		public enum MismatchType {
			case query
			case body
			case bodyType
			case headers
			case unknown(String)
		}

		public struct Expected {
			let expectedString: String
			let expectedIntArray: [Int]
		}

		public struct Actual {
			let actualString: String
			let actualIntArray: [Int]
		}
	}
}

extension PactVerificationFailure: Decodable {
	enum CodingKeys: String, CodingKey {
		case type
		case method
		case path
		case request
		case mismatches
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		type = try container.decode(FailureType.self, forKey: .type)
		method = try container.decode(String.self, forKey: .method)
		path = try container.decode(String.self, forKey: .path)
		request = try? container.decode(Request.self, forKey: .request)
		mismatches = (try? container.decodeIfPresent([Mismatch].self, forKey: .mismatches)) ?? []
	}
}

extension PactVerificationFailure.Request: CustomStringConvertible {
	public var description: String {
		"""
		Request:
		  \(method) \(path)
		  \((headers?.map { k, v in "\(k): \(v)" } ?? []).joined(separator: "\n  "))
		--
		"""
	}
}

extension PactVerificationFailure: CustomStringConvertible {

	public var description: String {

		"""
		Failure: \(type.description) "\(method) \(path)"
		\(request?.description ?? "")
		\(mismatches.map(\.description).joined(separator: "\n"))
		"""
	}

}

extension PactVerificationFailure.Request: Decodable {}

extension PactVerificationFailure.Mismatch: Decodable, CustomStringConvertible {
	public var description: String {

		var items: [String] = []

		items.append("Expected: \(expected.expectedString)")

		if let actual = actual?.actualString {
			items.append("Actual: \(actual)")
		}

		if let parameter = parameter {
			items.append("Parameter: \(parameter)")
		}

		return
			"""
			\(type.rawValue): \(mismatch ?? "")
			  \(items.joined(separator: "\n  "))
			"""
	}

}

extension PactVerificationFailure.Mismatch.MismatchType: RawRepresentable, Decodable {

	public init(rawValue: String) {
		switch rawValue {
		case "QueryMismatch": self = .query
		case "BodyTypeMismatch": self = .bodyType
		case "BodyMismatch": self = .body
		case "HeaderMismatch": self = .headers
		default: self = .unknown(rawValue)
		}
	}

	public var rawValue: String {
		switch self {
		case .query:
			return "QueryMismatch"
		case .bodyType:
			return "BodyTypeMismatch"
		case .body:
			return "BodyMismatch"
		case .headers:
			return "HeaderMismatch"
		case .unknown(let value):
			return value
		}
	}
}

extension PactVerificationFailure.FailureType: RawRepresentable, Decodable, CustomStringConvertible {

	public init?(rawValue: String) {
		switch rawValue {
		case "missing-request":
			self = .missing
		case "request-not-found":
			self = .requestNotFound
		case "request-mismatch":
			self = .requestMismatch
		case "mock-server-parsing-fail":
			self = .mockServerParsingFail
		default:
			self = .unknown(rawValue)
		}
	}

	public var rawValue: String {
		switch self {
		case .missing:
			return "missing-request"
		case .requestMismatch:
			return "request-mismatch"
		case .requestNotFound:
			return "request-not-found"
		case .mockServerParsingFail:
			return "mock-server-parsing-fail"
		case .unknown(let value):
			return value
		}
	}

	public var description: String {

		switch self {
		case .missing:
			return "Missing request"
		case .requestNotFound:
			return "Unexpected request"
		case .requestMismatch:
			return "Request does not match"
		case .mockServerParsingFail:
			return
				"""
				Failed to parse Mock Server error response!
				Please report this as an issue. Provide this test as an example to help us debug and improve this framework.
				"""
		case .unknown(let value):
			return
				"""
				Unknown type \(value)! Not entirely sure what happened!
				Please report this as an issue. Provide this test as an example to help us debug and improve this framework.
				"""
		}
	}
}

// This is only used to handle Mock Server's bug where it returns a String or an Array<Int> depending on the request. :|
extension PactVerificationFailure.Mismatch.Expected: Decodable {

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()

		do {
			expectedString = try container.decode(String.self)
			expectedIntArray = []
		} catch {
			expectedIntArray = try container.decode([Int].self)
			expectedString = expectedIntArray.map { "\($0)" }.joined(separator: ",")
		}
	}

}

extension PactVerificationFailure.Mismatch.Actual: Decodable {

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		do {
			actualString = try container.decode(String.self)
			actualIntArray = []
		} catch {
			actualIntArray = try container.decode([Int].self)
			actualString = actualIntArray.map { "\($0)" }.joined(separator: ",")
		}
	}

}
