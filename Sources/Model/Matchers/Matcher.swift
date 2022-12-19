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

import Foundation

public protocol Matcher: Encodable {
    // no additional members
}

public struct AnyMatcher: Matcher {
    var matcher: any Matcher
 
    public init(_ matcher: any Matcher) {
        self.matcher = matcher
    }
    
    public func encode(to encoder: Encoder) throws {
        try matcher.encode(to: encoder)
    }
}

public extension Matcher {
    
    func asAny() -> AnyMatcher {
        AnyMatcher(self)
    }
    
    // MARK: - Matchers
    
    static func oneLike(_ value: [String: AnyMatcher]) -> AnyMatcher {
        SimpleMatcher(type: "type", value: value, max: 1).asAny()
    }
    
    static func multipleLike(_ value: [String: AnyMatcher], min: Int? = nil, max: Int? = nil) -> AnyMatcher {
        SimpleMatcher(type: "type", value: [value], min: min, max: max).asAny()
    }
    
    static func multipleLike(_ value: AnyMatcher, min: Int? = nil, max: Int? = nil) -> AnyMatcher {
        SimpleMatcher(type: "type", value: [value], min: min, max: max).asAny()
    }
    
    static func eachLike(_ value: [String: AnyMatcher], min: Int? = nil, max: Int? = nil) -> AnyMatcher {
        SimpleMatcher(type: "type", value: value, min: min, max: max).asAny()
    }
    
    static func eachLike<T: Encodable>(_ value: T, min: Int? = nil, max: Int? = nil) -> AnyMatcher {
        SimpleMatcher(type: "type", value: value, min: min, max: max).asAny()
    }
    
    // MARK: - Pact Specification v1 matchers
    
    /// A matcher that checks that the values are equal.
    ///
    /// - Note: Requires `Pact.Specification.v1`.
    /// - Parameters:
    ///   - value: The value to match with.
    ///
    static func equals<T: Encodable>(_ value: T) -> AnyMatcher {
        SimpleMatcher(type: "equality", value: value).asAny()
    }
    
    // MARK: - Pact Specification v2 matchers
    
    /// A matcher that executes a regular expression match against the string representation of a value.
    ///
    /// - Note: Requires `Pact.Specification.v2`.
    /// - Parameters:
    ///   - regex: The regex to use when matching.
    ///   - example: An example value that matches the `regex`.
    ///
    static func regex(_ regex: String, example: String) -> AnyMatcher {
        RegexMatcher(example: example, regex: regex).asAny()
    }
    
    /// A matcher that executes a type based match against the value, that is, they are equal if they are the same type.
    ///
    /// - Note: Requires `Pact.Specification.v2`.
    /// - Parameters:
    ///   - value: An example value to match the type of.
    ///
    static func like<T: Encodable>(_ value: T) -> AnyMatcher {
        SimpleMatcher(type: "type", value: value).asAny()
    }
    
    /// A matcher that executes a type based match against the values, that is, they are equal if they are the same type.
    ///
    /// In addition, if the values represent a collection, the length of the actual value is compared against the minimum.
    ///
    /// - Note: Requires `Pact.Specification.v2`.
    /// - Parameters:
    ///   - values: The example values.
    ///   - min: The minimum length of the array of values.
    ///
    static func like<T: Encodable>(_ values: [T], min: Int) -> AnyMatcher {
        SimpleMatcher(type: "type", value: values, min: min).asAny()
    }
    
    /// A matcher that executes a type based match against the values, that is, they are equal if they are the same type.
    ///
    /// In addition, if the values represent a collection, the length of the actual value is compared against the maximum.
    ///
    /// - Note: Requires `Pact.Specification.v2`.
    /// - Parameters:
    ///   - values: The example values.
    ///   - max: The maximum length of the array of values.
    ///
    static func like<T: Encodable>(_ values: [T], max: Int) -> AnyMatcher {
        SimpleMatcher(type: "type", value: values, max: max).asAny()
    }
    
    /// A matcher that executes a type based match against the values, that is, they are equal if they are the same type.
    ///
    /// In addition, if the values represent a collection, the length of the actual value is compared against the minimum and maximum.
    ///
    /// - Note: Requires `Pact.Specification.v2`.
    /// - Parameters:
    ///   - values: The example values.
    ///   - min: The minimum length of the array of values.
    ///   - max: The maximum length of the array of values.
    ///
    static func like<T: Encodable>(_ values: [T], min: Int, max: Int) -> AnyMatcher {
        SimpleMatcher(type: "type", value: values, min: min, max: max).asAny()
    }
    
    // MARK: - Pact Specification v3 matchers
    
    /// A matcher that checks if the string representation of a value contains the substring.
    ///
    /// - Parameters:
    ///   - value: The substring to match with.
    ///
    static func includes<T: StringProtocol & Encodable>(_ value: T) -> AnyMatcher {
        SimpleMatcher(type: "include", value: value).asAny()
    }
        
    /// A matcher that checks if the type of the value is an integer.
    ///
    /// - Note: Requires `Pact.Specification.v3`.
    ///
    static func likeInteger<T: BinaryInteger & Encodable>(_ value: T) -> AnyMatcher {
        SimpleMatcher(type: "integer", value: value).asAny()
    }

    /// A matcher that checks if the type of the value is a number with decimal places.
    ///
    /// - Note: Requires `Pact.Specification.v3`.
    ///
    static func likeDecimal<T: FloatingPoint & Encodable>(_ value: T) -> AnyMatcher {
        SimpleMatcher(type: "decimal", value: value).asAny()
    }
    
    /// A matcher that checks if the type of the value is an number.
    ///
    /// - Note: Requires `Pact.Specification.v3`.
    ///
    static func likeNumber<T: Numeric & Encodable>(_ value: T) -> AnyMatcher {
        SimpleMatcher(type: "number", value: value).asAny()
    }
    
    /// A matcher that matches the string representation of a value against the datetime format.
    ///
    /// - Note: Requires `Pact.Specification.v3`.
    /// - Parameters:
    ///   - value: An example value.
    ///   - format: The date time format to match against  (eg, `"yyyy-MM-dd HH:mm:ss"`).
    ///
    static func timestamp(_ value: String, format: String) -> AnyMatcher {
        SimpleMatcher(type: "datetime", value: value, format: format).asAny()
    }
    
    /// A matcher that matches the string representation of a value against the time format.
    ///
    /// - Note: Requires `Pact.Specification.v3`.
    /// - Parameters:
    ///   - value: An example value.
    ///   - format: The time format to match against  (eg, `"HH:mm:ss"`).
    ///
    static func time(_ value: String, format: String) -> AnyMatcher {
        SimpleMatcher(type: "time", value: value, format: format).asAny()
    }
    
    /// A matcher that matches the string representation of a value against the date format.
    ///
    /// - Note: Requires `Pact.Specification.v3`.
    /// - Parameters:
    ///   - value: An example value.
    ///   - format: The date format to match against (eg, `"yyyy-MM-dd"`).
    ///
    static func date(_ value: String, example: String, format: String) -> AnyMatcher {
        SimpleMatcher(type: "date", value: value, format: format).asAny()
    }
    
    /// A matcher that matches if the value is a null value (this is content specific, for JSON will match a JSON null).
    ///
    /// - Note: Requires `Pact.Specification.v3`.
    ///
    static func null() -> AnyMatcher {
        SimpleMatcher(type: "null", value: nil as String?).asAny()
    }
 
    /// A matcher that matches if the value is a boolean value (booleans and the string values `"true"` and `"false"`).
    ///
    /// - Note: Requires `Pact.Specification.v3`.
    ///
    static func bool(_ value: Bool) -> AnyMatcher {
        SimpleMatcher(type: "boolean", value: value).asAny()
    }
    
    /// A matcher that matches binary data by its content type (magic file check).
    ///
    /// - Note: Requires `Pact.Specification.v3`.
    ///
    /// - Parameters:
    ///   - value: The MIME content type to match against eg (`"image/jpeg"`).
    ///
    static func contentType(_ value: String) -> AnyMatcher {
        SimpleMatcher(type: "contentType", value: value).asAny()
    }
    
    /// A matcher that matches the values in a map/dictionary, ignoring the keys
    ///
    /// - Note: Requires `Pact.Specification.v3`.
    ///
    /// - Parameters:
    ///   - values: A dictionary to match against. The keys don't matter.
    ///
    static func values<T: Encodable>(_ value: [String: T]) -> AnyMatcher {
        SimpleMatcher(type: "values", value: value).asAny()
    }
    
    // MARK: - Pact Specification v4 matchers
    
    // TODO: "arrayContains"
    
    /// A matcher that matches the response status code.
    ///
    /// - Note: Requires `Pact.Specification.v4`.
    ///
    static func statusCode(_ statusCode: HTTPStatus) -> AnyMatcher {
        switch statusCode {
        case .information:
            return SimpleMatcher(type: "statusCode", value: "information").asAny()
        case .success:
            return SimpleMatcher(type: "statusCode", value: "success").asAny()
        case .redirect:
            return SimpleMatcher(type: "statusCode", value: "redirect").asAny()
        case .clientError:
            return SimpleMatcher(type: "statusCode", value: "clientError").asAny()
        case .serverError:
            return SimpleMatcher(type: "statusCode", value: "serverError").asAny()
        case .nonError:
            return SimpleMatcher(type: "statusCode", value: "nonError").asAny()
        case .error:
            return SimpleMatcher(type: "statusCode", value: "error").asAny()
        case .statusCodes(let codes):
            return SimpleMatcher(type: "statusCode", value: codes).asAny()
        }
    }
    
    /// A matcher that matches a value that must be present and not empty (not null or the empty string).
    ///
    /// - Note: Requires `Pact.Specification.v4`.
    ///
    static func notEmpty() -> AnyMatcher {
        SimpleMatcher(type: "notEmpty", value: nil as String?).asAny()
    }
    
    /// A matcher that matches a value that must be valid based on the `semver` specification.
    ///
    /// - Note: Requires `Pact.Specification.v4`.
    ///
    /// - Parameters:
    ///   - value: An example value (eg: `"1.2.3"`)
    ///
    static func semver(_ value: String) -> AnyMatcher {
        SimpleMatcher(type: "semver", value: value).asAny()
    }
    
    // TODO: "eachKey", "eachValue"
    
    // MARK: - Generators
    
    //case regex = "Regex"
    //case providerState = "ProviderState"
    //case mockServerUrl = "MockServerURL"
    
    static func randomString(_ value: String, size: Int? = nil) -> AnyMatcher {        
        SimpleMatcher(type: "type", value: value, generator: .randomString, size: size).asAny()
    }
    
    static func randomInteger<T: BinaryInteger & Encodable>(like value: T, range: ClosedRange<Int>? = nil) -> AnyMatcher {
        SimpleMatcher(type: "type", value: value, generator: .randomInt, min: range?.lowerBound, max: range?.upperBound).asAny()
    }

    static func randomDecimal<T: FloatingPoint & Encodable>(like value: T) -> AnyMatcher {
        SimpleMatcher(type: "type", value: value, generator: .randomDecimal).asAny()
    }
    
    static func randomBoolean(_ value: Bool) -> AnyMatcher {
        SimpleMatcher(type: "type", value: value, generator: .randomBoolean).asAny()
    }
    
    static func randomUUID(_ value: String, format: UUIDFormat = .simple) -> AnyMatcher {
        SimpleMatcher(type: "type", value: value, generator: .uuid, format: format.rawValue).asAny()
    }
    
    static func randomUUID(_ value: UUID) -> AnyMatcher {
        SimpleMatcher(type: "type", value: value.uuidString, generator: .uuid, format: UUIDFormat.upperCaseHyphenated.rawValue).asAny()
    }
    
    static func randomHexadecimal(_ value: String, digits: Int? = nil) -> AnyMatcher {
        SimpleMatcher(type: "type", value: value, generator: .randomHex, digits: digits).asAny()
    }

    /// Generate a random date.
    ///
    /// The base date is normally the current system clock.  Given the base date-time of 2000-01-01T10:00Z, then the following will resolve to:
    /// - Parameters:
    ///   - value: Example value.
    ///   - format: The date format (eg, yyyy-MM-dd)
    ///   - expression: An expression to manipulate the generated date.
    ///
    /// Expression | Resulting date-time
    /// --|--
    /// `nil` | `"2000-01-01T10:00Z"`
    /// `"now"`| `2000-01-01T10:00Z`
    /// `"today"` | `"2000-01-01T10:00Z"`
    /// `"yesterday"` | `"1999-12-31T10:00Z"`
    /// `"tomorrow"` | `"2000-01-02T10:00Z"`
    /// `"+ 1 day"` | `"2000-01-02T10:00Z"`
    /// `"+ 1 week"` | `"2000-01-08T10:00Z"`
    /// `"- 2 weeks"` | `"1999-12-18T10:00Z"`
    /// `"+ 4 years"` | `"2004-01-01T10:00Z"`
    /// `"tomorrow+ 4 years"` | `"2004-01-02T10:00Z"`
    /// `"next week"` | `"2000-01-08T10:00Z"`
    /// `"last month"` | `"1999-12-01T10:00Z"`
    /// `"next fortnight"` | `"2000-01-15T10:00Z"`
    /// `"next monday"` | `"2000-01-03T10:00Z"`
    /// `"last wednesday"` | `"1999-12-29T10:00Z"`
    /// `"next mon"` | `"2000-01-03T10:00Z"`
    /// `"last december"` | `"1999-12-01T10:00Z"`
    /// `"next jan"` | `"2001-01-01T10:00Z"`
    /// `"next june + 2 weeks"` | `"2000-06-15T10:00Z"`
    /// `"last mon + 2 weeks"` | `"2000-01-10T10:00Z"`
    /// `"+ 1 day - 2 weeks"` | `"1999-12-19T10:00Z"`
    /// `"last december + 2 weeks + 4 days"` | `"1999-12-19T10:00Z"`
    /// `"@ now"` | `"2000-01-01T10:00Z"` |
    /// `"@ midnight"` | `"2000-01-01T00:00Z"`
    /// `"@ noon"` | `"2000-01-01T12:00Z"` |
    /// `"@ 2 o'clock"` | `"2000-01-01T14:00Z"`
    /// `"@ 12 o'clock am"` | `"2000-01-01T12:00Z"`
    /// `"@ 1 o'clock pm"` | `"2000-01-01T13:00Z"`
    /// `"@ + 1 hour"` | `"2000-01-01T11:00Z"`
    /// `"@ - 2 minutes"` | `"2000-01-01T09:58Z"`
    /// `"@ + 4 seconds"` | `"2000-01-01T10:00:04Z"`
    /// `"@ + 4 milliseconds"` | `"2000-01-01T10:00:00.004Z"`
    /// `"@ midnight+ 4 minutes"` | `"2000-01-01T00:04Z"`
    /// `"@ next hour"` | `"2000-01-01T11:00Z"`
    /// `"@ last minute"` | `"2000-01-01T09:59Z"`
    /// `"@ now + 2 hours - 4 minutes"` | `"2000-01-01T11:56Z"`
    /// `"@  + 2 hours - 4 minutes"` | `"2000-01-01T11:56Z"`
    /// `"today @ 1 o'clock"` | `"2000-01-01T13:00Z"`
    /// `"yesterday @ midnight"` | `"1999-12-31T00:00Z"`
    /// `"yesterday @ midnight - 1 hour"` | `"1999-12-30T23:00Z"`
    /// `"tomorrow @ now"` | `"2000-01-02T10:00Z"`
    /// `"+ 1 day @ noon"` | `"2000-01-02T12:00Z"`
    /// `"+ 1 week @ +1 hour"` | `"2000-01-08T11:00Z"`
    /// `"- 2 weeks @ now + 1 hour"` | `"1999-12-18T11:00Z"`
    /// `"+ 4 years @ midnight"` | `"2004-01-01T00:00Z"`
    /// `"tomorrow + 4 years @ 3 o'clock + 40 milliseconds"` | `"2004-01-02T15:00:00.040Z"`
    /// `"next week @ next hour"` | `"2000-01-08T11:00Z"`
    /// `"last month @ last hour"` | `"1999-12-01T09:00Z"`
    static func randomDate(_ value: String, format: String, expression: String? = nil) -> AnyMatcher {
        SimpleMatcher(type: "type", value: value, generator: .date, format: format, expression: expression).asAny()
    }
    
    static func randomDatetime(_ value: String, format: String, expression: String? = nil) -> AnyMatcher {
        SimpleMatcher(type: "type", value: value, generator: .dateTime, format: format, expression: expression).asAny()
    }
    
    static func randomTime(_ value: String, format: String, expression: String? = nil) -> AnyMatcher {
        SimpleMatcher(type: "type", value: value, generator: .time, format: format, expression: expression).asAny()
    }
        
}
