//
//  MultipleRewardsRoutable.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

protocol MultipleRewardsRoutable: AnyObject {
    func openStakingSingleActionFlow(action: UnstakingModel.Action)
    func dismiss()
}
