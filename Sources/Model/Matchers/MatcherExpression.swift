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
 
class MatcherExpression {

    enum Error: LocalizedError {
        case failedToParse(String?)
    }
    
    enum ValueType {
        /// If the type is unknown
        case unknown
        /// String type
        case string
        /// Numeric type
        case number
        /// Integer numeric type (no significant figures after the decimal point)
        case integer
        /// Decimal numeric type (at least one significant figure after the decimal point)
        case decimal
        /// Boolean type
        case boolean
    }
    
    enum RuleResult: Equatable {
        public enum RuleType: UInt16 {
            case equality = 1
            case regex = 2
            case type = 3
            case minType = 4
            case maxType = 5
            case minMaxType = 6
            case timestamp = 7
            case time = 8
            case date = 9
            case include = 10
            case number = 11
            case integer = 12
            case decimal = 13
            case null = 14
            case contentType = 15
            case arrayContains = 16
            case values = 17
            case boolean = 18
            case statusCode = 19
            case notEmpty = 20
            case semver = 21
            case eachKey = 22
            case eachValue = 23
        }
        
        case matchingRule(RuleType?, String)
        case matchingReference(String)
    }
    
    private var handle: OpaquePointer

    init(_ expression: String) throws {
        guard let handle = pactffi_parse_matcher_definition(expression) else {
            throw Error.failedToParse(nil)
        }
        
        if let errorMessageCString = pactffi_matcher_definition_error(handle) {
            let errorMessage = String(cString: errorMessageCString)
            guard errorMessage.isEmpty else {
                throw Error.failedToParse(errorMessage)
            }
        }
        
        self.handle = handle
    }
    
    deinit {
        pactffi_matcher_definition_delete(handle)
    }
    
    /// The type of value detected after parsing the expression.
    var valueType: ValueType {
        ValueType(rawValue: pactffi_matcher_definition_value_type(handle))
    }
    
    var value: String? {
        guard let cString = pactffi_matcher_definition_value(handle) else {
            return nil
        }
        
        defer { pactffi_string_delete(UnsafeMutablePointer(mutating: cString)) }
        
        return String(cString: cString)
    }
    
    var generatorJSON: String? {
        let generator = pactffi_matcher_definition_generator(handle)
        guard let cString = pactffi_generator_to_json(generator) else {
            return nil
        }
        defer { pactffi_string_delete(UnsafeMutablePointer(mutating: cString)) }
        
        return String(cString: cString)
    }
    
    var results: [RuleResult] {
        var results: [RuleResult] = []
        
        let iter = pactffi_matcher_definition_iter(handle)
        defer { pactffi_matching_rule_iter_delete(iter) }
        
        while let result = pactffi_matching_rule_iter_next(iter) {
            switch result.pointee.tag {
            case MatchingRuleResult_MatchingRule:
                
                let type = RuleResult.RuleType(rawValue: result.pointee.matching_rule._0)
                let example = result.pointee.matching_rule._1.map(String.init(cString:)) ?? ""
                
                // FIXME: Can't turn every rule result into json (Rust code crashes)
                /*
                if type != .equality && type != .timestamp && type != .eachValue && type != .regex && type != .eachKey {
                    let jsonCString = pactffi_matching_rule_to_json(result.pointee.matching_rule._2)
                    defer {
                        if jsonCString != nil {
                            pactffi_string_delete(UnsafeMutablePointer(mutating: jsonCString))
                        }
                    }
                }
                */
                
                let ruleResult = RuleResult.matchingRule(type, example)
                    
                results.append(ruleResult)
            case MatchingRuleResult_MatchingReference:
                let ruleResult = RuleResult.matchingReference(String(cString: result.pointee.matching_reference))
                results.append(ruleResult)
                
            default:
                // Unknown tag
                break
            }
        }
        
        return results
    }
}

extension MatcherExpression.ValueType: RawRepresentable {
    
    public init(rawValue: ExpressionValueType) {
        switch rawValue {
        case ExpressionValueType_String:
            self = .string
        case ExpressionValueType_Number:
            self = .number
        case ExpressionValueType_Integer:
            self = .integer
        case ExpressionValueType_Decimal:
            self = .decimal
        case ExpressionValueType_Boolean:
            self = .boolean
        case ExpressionValueType_Unknown:
            self = .unknown
        default:
            self = .unknown
        }
    }
    
    public var rawValue: ExpressionValueType {
        switch self {
        case .string: return ExpressionValueType_String
        case .number: return ExpressionValueType_Number
        case .integer: return ExpressionValueType_Integer
        case .decimal: return ExpressionValueType_Decimal
        case .boolean: return ExpressionValueType_Boolean
        case .unknown: return ExpressionValueType_Unknown
        }
    }
}
