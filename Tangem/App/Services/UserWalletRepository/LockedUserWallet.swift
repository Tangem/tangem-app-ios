//
//  LockedUserWallet.swift
//  Tangem
//
//  Created by Alexander Osokin on 31.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class LockedUserWallet: UserWalletModel {
    let walletModelsManager: WalletModelsManager = LockedWalletModelsManager()
    let userTokenListManager: UserTokenListManager = LockedUserTokenListManager()
    var signer: TangemSigner

    var tokensCount: Int? { nil }

    var cardsCount: Int { config.cardsCount }

    var isMultiWallet: Bool { config.hasFeature(.multiCurrency) }

    var userWalletId: UserWalletId { .init(value: userWallet.userWalletId) }

    var updatePublisher: AnyPublisher<Void, Never> { .just }

    private(set) var userWallet: UserWallet

    private let config: UserWalletConfig

    init(with userWallet: UserWallet) {
        self.userWallet = userWallet
        config = UserWalletConfigFactory(userWallet.cardInfo()).makeConfig()
        signer = TangemSigner(with: userWallet.card.cardId, sdk: config.makeTangemSdk())
    }

    func initialUpdate() {}

    func updateWalletName(_ name: String) {
        userWallet.name = name
    }

    func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalanceProvider.TotalBalance>, Never> {
        .just(output: .loaded(.init(balance: 0, currencyCode: "", hasError: false)))
    }
}
