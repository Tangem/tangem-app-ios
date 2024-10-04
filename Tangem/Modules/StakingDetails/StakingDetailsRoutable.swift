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
    func openMultipleRewards()
    func openUnstakingFlow(action: UnstakingModel.Action)
    func openRestakingFlow(action: RestakingModel.Action)
    func openStakingSingleActionFlow(action: StakingSingleActionModel.Action)
    func openWhatIsStaking()
}
