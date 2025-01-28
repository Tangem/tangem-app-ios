//
//  FakeUserWalletModel.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk

class FakeUserWalletModel: UserWalletModel, ObservableObject {
    var hasImportedWallets: Bool { false }
    var keysDerivingInteractor: any KeysDeriving { KeysDerivingMock() }
    var keysRepository: KeysRepository { CommonKeysRepository(with: []) }
    var name: String { "" }
    let emailData: [EmailCollectedData] = []
    let backupInput: OnboardingInput? = nil
    let walletModelsManager: WalletModelsManager
    let userTokenListManager: UserTokenListManager
    let userTokensManager: UserTokensManager
    let totalBalanceProvider: TotalBalanceProviding
    let signer: TangemSigner = .init(filter: .cardId(""), sdk: .init(), twinKey: nil)
    let config: UserWalletConfig
    let isUserWalletLocked: Bool
    let userWalletId: UserWalletId
    var hasBackupCards: Bool { cardsCount > 1 }
    var emailConfig: EmailConfig? { nil }
    var cardsCount: Int
    var totalSignedHashes: Int { 1 }

    var tangemApiAuthData: TangemApiTarget.AuthData {
        .init(cardId: "", cardPublicKey: Data())
    }

    var analyticsContextData: AnalyticsContextData {
        .init(
            productType: .other,
            batchId: "",
            firmware: "",
            baseCurrency: "",
            userWalletId: userWalletId
        )
    }

    var wcWalletModelProvider: WalletConnectWalletModelProvider {
        CommonWalletConnectWalletModelProvider(walletModelsManager: walletModelsManager)
    }

    var userWalletName: String { _userWalletNamePublisher.value }

    var tokensCount: Int? { walletModelsManager.walletModels.filter { !$0.isMainToken }.count }
    var updatePublisher: AnyPublisher<Void, Never> { _updatePublisher.eraseToAnyPublisher() }
    var cardImagePublisher: AnyPublisher<CardImageResult, Never>

    private let _updatePublisher: PassthroughSubject<Void, Never> = .init()
    private let _userWalletNamePublisher: CurrentValueSubject<String, Never>

    init(
        userWalletName: String,
        isUserWalletLocked: Bool,
        isDelayed: Bool,
        cardsCount: Int,
        userWalletId: UserWalletId,
        walletManagers: [FakeWalletManager],
        config: UserWalletConfig
    ) {
        self.isUserWalletLocked = isUserWalletLocked
        self.cardsCount = cardsCount
        self.userWalletId = userWalletId
        self.config = config
        _userWalletNamePublisher = .init(userWalletName)

        walletModelsManager = FakeWalletModelsManager(walletManagers: walletManagers, isDelayed: isDelayed)
        let fakeUserTokenListManager = FakeUserTokenListManager(walletManagers: walletManagers, isDelayed: isDelayed)
        userTokenListManager = fakeUserTokenListManager
        userTokensManager = FakeUserTokensManager(
            derivationManager: FakeDerivationManager(pendingDerivationsCount: 5),
            userTokenListManager: fakeUserTokenListManager
        )
        totalBalanceProvider = TotalBalanceProviderMock()
        cardImagePublisher = Just(.cached(Assets.Cards.walletSingle.uiImage)).eraseToAnyPublisher()
    }

    func updateWalletName(_ name: String) {
        _userWalletNamePublisher.send(name)
        _updatePublisher.send(())
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        .just(output: .loading(cached: .none))
    }

    func validate() -> Bool {
        return true
    }

    func onBackupUpdate(type: BackupUpdateType) {}
    func addAssociatedCard(_ cardId: String) {}
}

extension FakeUserWalletModel: MainHeaderSupplementInfoProvider {
    var userWalletNamePublisher: AnyPublisher<String, Never> { _userWalletNamePublisher.eraseToAnyPublisher() }

    var cardHeaderImagePublisher: AnyPublisher<ImageType?, Never> {
        .just(output: config.cardHeaderImage)
    }

    var isTokensListEmpty: Bool { walletModelsManager.walletModels.isEmpty }
}

extension FakeUserWalletModel: AnalyticsContextDataProvider {
    func getAnalyticsContextData() -> AnalyticsContextData? {
        return nil
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
        isUserWalletLocked: false,
        isDelayed: true,
        cardsCount: 3,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [
            .ethWithTokensManager,
            .btcManager,
            .polygonWithTokensManager,
            .xrpManager,
        ],
        config: UserWalletConfigStubs.walletV2Stub
    )

    static let visa = FakeUserWalletModel(
        userWalletName: "Tangem Visa",
        isUserWalletLocked: false,
        isDelayed: false,
        cardsCount: 1,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [
            .visaWalletManager,
        ],
        config: UserWalletConfigStubs.visaStub
    )

    static let walletWithoutDelay = FakeUserWalletModel(
        userWalletName: "Just A Wallet",
        isUserWalletLocked: false,
        isDelayed: false,
        cardsCount: 1,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [
            .ethWithTokensManager,
            .btcManager,
            .polygonWithTokensManager,
            .xrpManager,
            .xlmManager,
        ],
        config: UserWalletConfigStubs.walletV2Stub
    )

    static let twins = FakeUserWalletModel(
        userWalletName: "Tangem Twins",
        isUserWalletLocked: true,
        isDelayed: true,
        cardsCount: 2,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [.btcManager],
        config: UserWalletConfigStubs.twinStub
    )

    static let xrpNote = FakeUserWalletModel(
        userWalletName: "XRP Note",
        isUserWalletLocked: false,
        isDelayed: true,
        cardsCount: 1,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [.xrpManager],
        config: UserWalletConfigStubs.xrpNoteStub
    )

    static let xlmBird = FakeUserWalletModel(
        userWalletName: "XLM Bird",
        isUserWalletLocked: false,
        isDelayed: true,
        cardsCount: 1,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [.xlmManager],
        config: UserWalletConfigStubs.xlmBirdStub
    )
}
