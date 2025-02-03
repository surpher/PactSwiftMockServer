//
//  Created by Marko Justinek on 15/1/2025.
//  Copyright © 2025 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

#if SWIFT_PACKAGE
import PactMockServer
#endif

internal extension InteractionPart {
    static var request: Self { InteractionPart(rawValue: 0) }
    static var response: Self { InteractionPart(rawValue: 1) }
}
