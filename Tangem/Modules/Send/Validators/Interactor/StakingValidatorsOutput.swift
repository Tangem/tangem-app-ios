//
//  StakingValidatorsOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 06.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

protocol StakingValidatorsOutput: AnyObject {
    func userDidSelected(validators: [ValidatorInfo])
}

class StakingValidatorsOutputMock: StakingValidatorsOutput {
    func userDidSelected(validators: [ValidatorInfo]) {}
}
