//
//  UserWalletModelMock.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class UserWalletModelMock: UserWalletModel {
    var hasImportedWallets: Bool { false }
    var keysDerivingInteractor: any KeysDeriving { KeysDerivingMock() }
    var keysRepository: KeysRepository { CommonKeysRepository(with: []) }
    var name: String { "" }
    var hasBackupCards: Bool { false }
    var emailConfig: EmailConfig? { nil }
    var tokensCount: Int? { 7 }
    var config: UserWalletConfig { fatalError("UserWalletConfigMock doesn't exist") }
    var userWalletId: UserWalletId { .init(value: Data()) }

    var walletModelsManager: WalletModelsManager { WalletModelsManagerMock() }

    var userTokensManager: UserTokensManager { UserTokensManagerMock() }

    var userTokenListManager: UserTokenListManager { UserTokenListManagerMock() }

    var signer: TangemSigner { fatalError("TangemSignerMock doesn't exist") }

    var updatePublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }

    var emailData: [EmailCollectedData] { [] }

    var tangemApiAuthData: TangemApiTarget.AuthData {
        .init(cardId: "", cardPublicKey: Data())
    }

    var backupInput: OnboardingInput? { nil }

    var cardImagePublisher: AnyPublisher<CardImageResult, Never> { Empty().eraseToAnyPublisher() }

    var cardHeaderImagePublisher: AnyPublisher<ImageType?, Never> { Empty().eraseToAnyPublisher() }

    var userWalletNamePublisher: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }

    var totalBalancePublisher: AnyPublisher<LoadingValue<TotalBalance>, Never> { Empty().eraseToAnyPublisher() }

    var cardsCount: Int { 3 }

    var isUserWalletLocked: Bool { false }

    var isTokensListEmpty: Bool { false }

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

    var totalSignedHashes: Int { 0 }

    func updateWalletName(_ name: String) {}

    func getAnalyticsContextData() -> AnalyticsContextData? { nil }

    func validate() -> Bool { true }

    func onBackupUpdate(type: BackupUpdateType) {}

    func addAssociatedCard(_ cardId: String) {}
}
