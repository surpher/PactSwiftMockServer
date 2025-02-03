//
//  Created by Marko Justinek on 27/1/2025.
//  Copyright © 2025 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

public struct PactMatcher<ValueType: Encodable>: Encodable {

    public var type: String
    public var value: ValueType
    public var generator: String?
    public var min: Int?
    public var max: Int?
    public var size: Int?
    public var digits: Int?
    public var format: String?
    public var expression: String?
    public var regex: String?
    public var example: String?

    enum CodingKeys: String, CodingKey {
        case type = "pact:matcher:type"
        case generator = "pact:generator:type"
        case value
        case min
        case max
        case size
        case digits
        case format
        case expression
        case regex
        case example
    }
}
