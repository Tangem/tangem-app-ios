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
    @Published var cardName: String

    let walletModelsManager: WalletModelsManager
    let userTokenListManager: UserTokenListManager
    let totalBalanceProvider: TotalBalanceProviding
    let signer: TangemSigner = .init(with: "", sdk: .init())

    let userWallet: UserWallet
    let isMultiWallet: Bool
    let isCardLocked: Bool
    let userWalletId: UserWalletId
    var cardsCount: Int

    var tokensCount: Int? { walletModelsManager.walletModels.filter { !$0.isMainToken }.count }
    var updatePublisher: AnyPublisher<Void, Never> { _updatePublisher.eraseToAnyPublisher() }

    private let _updatePublisher: PassthroughSubject<Void, Never> = .init()

    internal init(
        cardName: String,
        isMultiWallet: Bool,
        isCardLocked: Bool,
        cardsCount: Int,
        userWalletId: UserWalletId,
        walletModels: [WalletModel],
        userWallet: UserWallet
    ) {
        self.cardName = cardName
        self.isMultiWallet = isMultiWallet
        self.isCardLocked = isCardLocked
        self.cardsCount = cardsCount
        self.userWalletId = userWalletId
        walletModelsManager = WalletModelsManagerMock()
        userTokenListManager = CommonUserTokenListManager(hasTokenSynchronization: false, userWalletId: userWalletId.value, hdWalletsSupported: true)
        totalBalanceProvider = TotalBalanceProviderMock()
        self.userWallet = userWallet
    }

    func initialUpdate() {}

    func updateWalletName(_ name: String) {
        cardName = name
        _updatePublisher.send(())
    }

    func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalanceProvider.TotalBalance>, Never> {
        return .just(output: .loading)
    }
}

extension FakeUserWalletModel {
    static let allFakeWalletModels = [
        wallet3Cards,
        twins,
        xrpNote,
    ]

    static let wallet3Cards = FakeUserWalletModel(
        cardName: "William Wallet",
        isMultiWallet: true,
        isCardLocked: false,
        cardsCount: 3,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletModels: [
            WalletModel(
                walletManager: FakeWalletManager(wallet: .ethereumWalletStub),
                amountType: .coin,
                isCustom: false
            ),
            WalletModel(
                walletManager: FakeWalletManager(wallet: .ethereumWalletStub),
                amountType: .token(value: .sushiMock),
                isCustom: false
            ),
        ],
        userWallet: UserWalletStubs.walletV2Stub
    )

    static let twins = FakeUserWalletModel(
        cardName: "Tangem Twins",
        isMultiWallet: false,
        isCardLocked: true,
        cardsCount: 2,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletModels: [
            WalletModel(
                walletManager: FakeWalletManager(wallet: .btcWalletStub),
                amountType: .coin,
                isCustom: false
            ),
        ],
        userWallet: UserWalletStubs.twinStub
    )

    static let xrpNote = FakeUserWalletModel(
        cardName: "XRP Note",
        isMultiWallet: false,
        isCardLocked: false,
        cardsCount: 1,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletModels: [
            WalletModel(
                walletManager: FakeWalletManager(wallet: .xrpWalletStub),
                amountType: .coin,
                isCustom: false
            ),
        ],
        userWallet: UserWalletStubs.xrpNoteStub
    )
}
