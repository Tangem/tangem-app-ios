//
//  UserWalletStubs.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct UserWalletStubs {
    static var walletV2Stub: UserWallet = .init(
        userWalletId: Data.randomData(count: 32),
        name: "Wallet 2.0",
        card: .init(card: .walletV2),
        associatedCardIds: [
            "AF19000000000014",
            "AF19000000000025",
        ],
        walletData: .none,
        artwork: nil,
        isHDWalletAllowed: true
    )

    static var twinStub: UserWallet = .init(
        userWalletId: Data.randomData(count: 32),
        name: "Tangem Twins",
        card: .init(card: .twin),
        associatedCardIds: [],
        walletData: .twin(
            .init(
                blockchain: Blockchain.bitcoin(testnet: false).currencySymbol,
                token: nil
            ),
            .init(series: .cb62)
        ),
        artwork: nil,
        isHDWalletAllowed: false
    )

    static var xrpNoteStub: UserWallet = .init(
        userWalletId: Data.randomData(count: 32),
        name: "XRP Note",
        card: .init(card: .xrpNote),
        associatedCardIds: [],
        walletData: .file(.init(blockchain: "XRP", token: nil)),
        artwork: nil,
        isHDWalletAllowed: false
    )
}
