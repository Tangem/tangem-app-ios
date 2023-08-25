//
//  ReferralInputModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 25.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// TODO: Refactor userTokensManager interface to get rid of supportedBlockchains
struct ReferralInputModel {
    let userWalletId: Data
    let supportedBlockchains: SupportedBlockchainsSet
    let userTokensManager: UserTokensManager
}
