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
    
    static func like<T: Encodable>(_ value: T) -> AnyMatcher {
        SimpleMatcher(type: "type", value: value).asAny()
    }
    
    static func likeInteger<T: BinaryInteger & Encodable>(_ value: T) -> AnyMatcher {
        SimpleMatcher(type: "integer", value: value).asAny()
    }
        
    static func likeDecimal<T: FloatingPoint & Encodable>(_ value: T) -> AnyMatcher {
        SimpleMatcher(type: "decimal", value: value).asAny()
    }
    
    static func likeNumber<T: Numeric & Encodable>(_ value: T) -> AnyMatcher {
        SimpleMatcher(type: "number", value: value).asAny()
    }

    static func equals<T: Encodable>(_ value: T) -> AnyMatcher {
        SimpleMatcher(type: "equality", value: value).asAny()
    }
    
    static func includes<T: StringProtocol & Encodable>(_ value: T) -> AnyMatcher {
        SimpleMatcher(type: "include", value: value).asAny()
    }
    
    static func null() -> AnyMatcher {
        SimpleMatcher(type: "null", value: nil as String?).asAny()
    }
 
    static func regex(_ regex: String, example: String) -> AnyMatcher {
        RegexMatcher(example: example, regex: regex).asAny()
    }
}
