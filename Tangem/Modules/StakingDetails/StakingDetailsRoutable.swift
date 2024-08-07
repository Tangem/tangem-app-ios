//
//  StakingDetailsRoutable.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

protocol StakingDetailsRoutable: AnyObject {
    func openStakingFlow()
    func openClaimRewardsFlow()
    func openUnstakingFlow(validator: String)
    func openWhatIsStaking()
}
