//
//  UserWalletModelMock.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

class UserWalletModelMock: UserWalletModel {
    let emailData: [EmailCollectedData] = []
    let backupInput: OnboardingInput? = nil
    let twinInput: OnboardingInput? = nil

    var cardHeaderImage: ImageType?

    var isUserWalletLocked: Bool { false }

    var signer: TangemSigner = .init(with: nil, sdk: .init())

    var walletModelsManager: WalletModelsManager { WalletModelsManagerMock() }
    var userTokenListManager: UserTokenListManager { UserTokenListManagerMock() }
    var userTokensManager: UserTokensManager { UserTokensManagerMock() }

    var isMultiWallet: Bool { false }

    var tokensCount: Int? { 10 }

    var cardsCount: Int { 1 }

    var config: UserWalletConfig { UserWalletConfigFactory(userWallet.cardInfo()).makeConfig() }

    var userWalletId: UserWalletId { .init(with: Data()) }

    var userWallet: UserWallet {
        UserWallet(
            userWalletId: Data(),
            name: "",
            card: .init(card: .walletWithBackup),
            associatedCardIds: [],
            walletData: .none,
            artwork: nil,
            isHDWalletAllowed: false
        )
    }

    var updatePublisher: AnyPublisher<Void, Never> { .just }

    var userWalletNamePublisher: AnyPublisher<String, Never> { .just(output: "") }

    func initialUpdate() {}
    func updateWalletName(_ name: String) {}

    func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalanceProvider.TotalBalance>, Never> {
        .just(output: .loading)
    }
}
