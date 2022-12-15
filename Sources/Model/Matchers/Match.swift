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

import Foundation

public enum Match {
    
    /// Match a string property against a regex
    /// - Parameters:
    ///   - example: String example
    ///   - regex: Match regex
    ///
    public static func regex(_ regex: String, example: String) -> RegexMatcher {
        RegexMatcher(regex: regex, example: example)
    }
    
    /// Matcher which matches specifically on integers (i.e. not decimals)
    /// - Parameters:
    ///   - example: Example value
    ///
    public static func integer(_ example: Int) -> IntegerMatcher {
        IntegerMatcher(example)
    }
    
    /// Matcher which matches specifically on decimals (i.e. numbers with a fractional component)
    /// - Parameters:
    ///   - example: Example value
    ///
    public static func double(_ example: Double) -> DecimalMatcher {
        DecimalMatcher(example)
    }
    
    /// Matcher which matches specifically on decimals (i.e. numbers with a fractional component)
    /// - Parameters:
    ///   - example: Example value
    ///
    public static func decimal(_ example: Decimal) -> DecimalMatcher {
        DecimalMatcher(example)
    }
    
    /// Matcher which matches specifically any numeric type (fractional or not)
    /// - Parameters:
    ///   - example: Example value
    ///
    public static func numeric<T: Encodable & Numeric>(_ example: T) -> some Matcher {
        NumericMatcher(example)
    }
    
    /// Matcher which matches an exact value
    /// - Parameters:
    ///   - value: Exact value to match
    ///
    public static func equality<T: Encodable & Equatable>(_ value: T) -> some Matcher {
        EqualityMatcher(value)
    }
    
    /// Matcher which matches an explicit null value
    ///
    public static func null() -> NullMatcher {
        NullMatcher()
    }
    
    /// Matcher which checks that a string property includes an example string.
    /// - Parameters:
    ///   - example: Example value
    ///
    public static func include(_ example: String) -> IncludeMatcher {
        IncludeMatcher(example)
    }
    
    /// Matcher which checks for a boolean value
    /// - Parameters:
    ///   - example: Example value
    ///
    public static func bool(_ example: Bool) -> BooleanMatcher {
        BooleanMatcher(example)
    }
    
}
