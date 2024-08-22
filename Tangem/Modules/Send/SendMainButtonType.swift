//
//  SendMainButtonType.swift
//  Tangem
//
//  Created by Andrey Chukavin on 29.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum SendMainButtonType {
    case next
    case `continue`
    case action
    case close
}

enum SendFlowAdditionalActionType: Hashable {
    case restakeRewards

    var title: String {
        switch self {
        case .restakeRewards: Localization.stakingRestakeRewards
        }
    }

    var icon: MainButton.Icon? {
        switch self {
        case .restakeRewards: .trailing(Assets.tangemIcon)
        }
    }
}

enum SendFlowActionType: Hashable {
    case send
    case approve
    case stake
    case unstake
    case withdraw
    case claimRewards

    var title: String {
        switch self {
        case .send: Localization.commonSend
        case .approve: Localization.commonApprove
        case .stake: Localization.commonStake
        case .unstake: Localization.commonUnstake
        case .withdraw: Localization.stakingWithdraw
        case .claimRewards: Localization.commonClaimRewards
        }
    }
}

extension SendMainButtonType {
    func title(action: SendFlowActionType) -> String {
        switch self {
        case .next:
            Localization.commonNext
        case .continue:
            Localization.commonContinue
        case .action:
            action.title
        case .close:
            Localization.commonClose
        }
    }

    var icon: MainButton.Icon? {
        switch self {
        case .action:
            .trailing(Assets.tangemIcon)
        default:
            nil
        }
    }
}
