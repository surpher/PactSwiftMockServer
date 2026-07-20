//
//  Created by Marko Justinek on 17/12/2024.
//  Copyright © 2024 Marko Justinek. All rights reserved.
//
//  See LICENSE file for licensing information.
//

import Foundation

public protocol ProviderVerifying {

    /// Triggers the provider verification task
    func verifyProvider(options: VerificationOptions) -> Result<Bool, ProviderVerificationError>

}
