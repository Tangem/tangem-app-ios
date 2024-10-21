//
//  HederaNetworkResult.AccountBalance.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 20.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension HederaNetworkResult {
    /// Contains both HBAR and token balances for the account; used by the Consensus network layer.
    struct AccountBalance {
        typealias HBARBalance = AccountHbarBalance
        typealias TokensBalance = AccountTokensBalance

        let hbarBalance: HBARBalance
        let tokensBalance: TokensBalance
    }
}
