//
//  FakeUserWalletModel.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class FakeUserWalletModel: UserWalletModel, ObservableObject {
    let emailData: [EmailCollectedData] = []
    let backupInput: OnboardingInput? = nil
    let twinInput: OnboardingInput? = nil
    let walletModelsManager: WalletModelsManager
    let userTokenListManager: UserTokenListManager
    let userTokensManager: UserTokensManager
    let totalBalanceProvider: TotalBalanceProviding
    let signer: TangemSigner = .init(with: "", sdk: .init())

    let config: UserWalletConfig
    let userWallet: UserWallet
    let isMultiWallet: Bool
    let isUserWalletLocked: Bool
    let userWalletId: UserWalletId

    var cardsCount: Int

    var userWalletName: String { _userWalletNamePublisher.value }

    var tokensCount: Int? { walletModelsManager.walletModels.filter { !$0.isMainToken }.count }
    var updatePublisher: AnyPublisher<Void, Never> { _updatePublisher.eraseToAnyPublisher() }

    private let _updatePublisher: PassthroughSubject<Void, Never> = .init()
    private let _userWalletNamePublisher: CurrentValueSubject<String, Never>

    internal init(
        userWalletName: String,
        isMultiWallet: Bool,
        isUserWalletLocked: Bool,
        cardsCount: Int,
        userWalletId: UserWalletId,
        walletManagers: [FakeWalletManager],
        userWallet: UserWallet
    ) {
        self.isMultiWallet = isMultiWallet
        self.isUserWalletLocked = isUserWalletLocked
        self.cardsCount = cardsCount
        self.userWalletId = userWalletId
        config = UserWalletConfigFactory(userWallet.cardInfo()).makeConfig()
        _userWalletNamePublisher = .init(userWalletName)

        walletModelsManager = FakeWalletModelsManager(walletManagers: walletManagers)
        let fakeUserTokenListManager = FakeUserTokenListManager()
        userTokenListManager = fakeUserTokenListManager
        userTokensManager = FakeUserTokensManager(
            derivationManager: FakeDerivationManager(pendingDerivationsCount: 5),
            userTokenListManager: fakeUserTokenListManager
        )
        totalBalanceProvider = TotalBalanceProviderMock()

        self.userWallet = userWallet
        initialUpdate()
    }

    func initialUpdate() {}

    func updateWalletName(_ name: String) {
        _userWalletNamePublisher.send(name)
        _updatePublisher.send(())
    }

    func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalanceProvider.TotalBalance>, Never> {
        return .just(output: .loading)
    }
}

extension FakeUserWalletModel: MainHeaderInfoProvider {
    var userWalletNamePublisher: AnyPublisher<String, Never> { _userWalletNamePublisher.eraseToAnyPublisher() }

    var cardHeaderImage: ImageType? {
        UserWalletConfigFactory(userWallet.cardInfo()).makeConfig().cardHeaderImage
    }
}

extension FakeUserWalletModel {
    static let allFakeWalletModels = [
        wallet3Cards,
        twins,
        xrpNote,
    ]

    static let wallet3Cards = FakeUserWalletModel(
        userWalletName: "William Wallet",
        isMultiWallet: true,
        isUserWalletLocked: false,
        cardsCount: 3,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [.ethWithTokensManager, .btcManager, .polygonWithTokensManager, .xrpManager],
        userWallet: UserWalletStubs.walletV2Stub
    )

    static let twins = FakeUserWalletModel(
        userWalletName: "Tangem Twins",
        isMultiWallet: false,
        isUserWalletLocked: true,
        cardsCount: 2,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [.btcManager],
        userWallet: UserWalletStubs.twinStub
    )

    static let xrpNote = FakeUserWalletModel(
        userWalletName: "XRP Note",
        isMultiWallet: false,
        isUserWalletLocked: false,
        cardsCount: 1,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [.xrpManager],
        userWallet: UserWalletStubs.xrpNoteStub
    )
}
