//
//  StakingValidatorsRoutable.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

protocol StakingValidatorsRoutable: AnyObject {
    func userDidSelectedValidator()
}

class StakingValidatorsRoutableMock: StakingValidatorsRoutable {
    func userDidSelectedValidator() {}
}
