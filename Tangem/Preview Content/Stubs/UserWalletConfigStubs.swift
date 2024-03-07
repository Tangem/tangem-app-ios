//
//  UserWalletConfigStubs.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct UserWalletConfigStubs {
    static var walletV2Stub: UserWalletConfig = Wallet2Config(
        card: .init(card: .walletV2),
        isDemo: false,
        isRing: false
    )

    static var twinStub: UserWalletConfig = TwinConfig(
        card: .init(card: .twin),
        walletData: .init(blockchain: "BTC", token: nil),
        twinData: .init(series: .cb62, pairPublicKey: nil)
    )

    static var xrpNoteStub: UserWalletConfig = NoteConfig(
        card: .init(card: .xrpNote),
        noteData: .init(blockchain: "XRP", token: nil)
    )

    static var xlmBirdStub: UserWalletConfig = NoteConfig(
        card: .init(card: .xrpNote),
        noteData: .init(blockchain: "XLM", token: nil)
    )

    static var visaStub: UserWalletConfig = VisaConfig(
        card: .init(card: .visa)
    )
}
