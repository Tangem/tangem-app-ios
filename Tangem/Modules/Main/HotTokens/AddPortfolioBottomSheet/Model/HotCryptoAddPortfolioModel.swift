//
//  HotCryptoAddToPortfolioModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 16.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct HotCryptoAddToPortfolioModel: Identifiable {
    let id = UUID()
    let token: HotCryptoToken
    let userWalletName: String
    let tokenNetworkName: String

    init(token: HotCryptoToken, userWalletName: String) {
        self.token = token
        self.userWalletName = userWalletName

        tokenNetworkName = {
            let blockchain = Blockchain.allMainnetCases.first { $0.networkId == token.networkId }

            return blockchain?.displayName ?? ""
        }()
    }
}
