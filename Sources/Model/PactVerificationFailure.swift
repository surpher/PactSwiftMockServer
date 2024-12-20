//
//  Created by Marko Justinek on 27/4/20.
//  Copyright © 2020 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

public struct PactVerificationFailure: Sendable {

    public let type: FailureType
    public let method: String
    public let path: String
    public let request: Request?
    public let mismatches: [Mismatch]

    public enum FailureType: Sendable {
        case missing
        case requestNotFound
        case requestMismatch
        case mockServerParsingFail
        case unknown(String)
    }

    public struct Request: Sendable {
        let method: String
        let path: String
        let headers: [String: String]?
    }

    public struct Mismatch: Sendable {
        public let type: MismatchType
        public let expected: Expected
        public let actual: Actual?
        public let parameter: String?
        public let mismatch: String?

        public enum MismatchType: Sendable {
            case query
            case body
            case bodyType
            case headers
            case unknown(String)
        }

        public struct Expected: Sendable {
            let expectedString: String
            let expectedIntArray: [Int]
        }

        public struct Actual: Sendable {
            let actualString: String
            let actualIntArray: [Int]
        }
    }
}

// MARK: - Extensions

extension PactVerificationFailure: CustomStringConvertible {

    public var description: String {
        """
        Failure: \(type.description) "\(method) \(path)"
        \(request?.description ?? "")
        \(mismatches.map(\.description).joined(separator: "\n"))
        """
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

// MARK: - Request

extension PactVerificationFailure.Request: Decodable {}

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

// MARK: - Mismatch

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

// MARK: - MismatchType

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

extension PactVerificationFailure.Mismatch.MismatchType: Equatable { }

// MARK: FailureType

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

extension PactVerificationFailure.FailureType: Equatable {

    // Add Equatable conformance for associated values
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.missing, .missing):
            return true
        case (.requestNotFound, .requestNotFound):
            return true
        case (.requestMismatch, .requestMismatch):
            return true
        case (.mockServerParsingFail, .mockServerParsingFail):
            return true
        case (.unknown(let lhsValue), .unknown(let rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}

// MARK: - Expected

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

// MARK: - Actual

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
