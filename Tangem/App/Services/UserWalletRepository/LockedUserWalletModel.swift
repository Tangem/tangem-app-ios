//
//  LockedUserWalletModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 31.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class LockedUserWalletModel: UserWalletModel {
    let walletModelsManager: WalletModelsManager = LockedWalletModelsManager()
    let userTokenListManager: UserTokenListManager = LockedUserTokenListManager()
    let userTokensManager: UserTokensManager = LockedUserTokensManager()
    let config: UserWalletConfig
    var signer: TangemSigner

    var tokensCount: Int? { nil }

    var cardsCount: Int { config.cardsCount }

    var hasBackupCards: Bool { userWallet.cardInfo().card.backupStatus?.isActive ?? false }

    var hasImportedWallets: Bool { false }

    var emailConfig: EmailConfig? { nil }

    var userWalletId: UserWalletId { .init(value: userWallet.userWalletId) }

    var updatePublisher: AnyPublisher<Void, Never> { .just }

    var emailData: [EmailCollectedData] {
        var data = config.emailData

        let userWalletIdItem = EmailCollectedData(type: .card(.userWalletId), data: userWalletId.stringValue)
        data.append(userWalletIdItem)

        return data
    }

    var tangemApiAuthData: TangemApiTarget.AuthData {
        .init(cardId: userWallet.card.cardId, cardPublicKey: userWallet.card.cardPublicKey)
    }

    var cardImagePublisher: AnyPublisher<CardImageResult, Never> {
        let artwork: CardArtwork

        if let artworkInfo = userWallet.artwork {
            artwork = .artwork(artworkInfo)
        } else {
            artwork = .notLoaded
        }

        return cardImageProvider.loadImage(
            cardId: userWallet.card.cardId,
            cardPublicKey: userWallet.card.cardPublicKey,
            artwork: artwork
        )
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        .just(output: .loaded(balance: 0))
    }

    var analyticsContextData: AnalyticsContextData {
        AnalyticsContextData(
            card: userWallet.cardInfo().card,
            productType: config.productType,
            embeddedEntry: config.embeddedBlockchain,
            userWalletId: userWalletId
        )
    }

    var wcWalletModelProvider: WalletConnectWalletModelProvider {
        CommonWalletConnectWalletModelProvider(walletModelsManager: walletModelsManager)
    }

    var totalSignedHashes: Int {
        0
    }

    var keysRepository: KeysRepository { CommonKeysRepository(with: []) }
    var keysDerivingInteractor: any KeysDeriving { KeysDerivingCardInteractor(with: userWallet.cardInfo()) }

    var name: String { userWallet.cardInfo().name }

    let backupInput: OnboardingInput? = nil

    private let userWallet: StoredUserWallet
    private let cardImageProvider = CardImageProvider()

    init(with userWallet: StoredUserWallet) {
        self.userWallet = userWallet
        config = UserWalletConfigFactory(userWallet.cardInfo()).makeConfig()
        signer = TangemSigner(filter: .cardId(""), sdk: .init(), twinKey: nil)
    }

    func updateWalletName(_ name: String) {
        // Renaming locked wallets is prohibited
    }

    func validate() -> Bool {
        // Nothing to validate for locked wallets
        return true
    }

    func onBackupUpdate(type: BackupUpdateType) {}

    func addAssociatedCard(_ cardId: String) {}
}

extension LockedUserWalletModel: MainHeaderSupplementInfoProvider {
    var isUserWalletLocked: Bool { true }

    var userWalletNamePublisher: AnyPublisher<String, Never> {
        .just(output: userWallet.name)
    }

    var cardHeaderImagePublisher: AnyPublisher<ImageType?, Never> {
        .just(output: config.cardHeaderImage)
    }

    var isTokensListEmpty: Bool { false }
}

extension LockedUserWalletModel: AnalyticsContextDataProvider {
    func getAnalyticsContextData() -> AnalyticsContextData? {
        let cardInfo = userWallet.cardInfo()
        let embeddedEntry = config.embeddedBlockchain
        let baseCurrency = embeddedEntry?.tokens.first?.symbol ?? embeddedEntry?.blockchainNetwork.blockchain.currencySymbol

        return AnalyticsContextData(
            productType: config.productType,
            batchId: cardInfo.card.batchId,
            firmware: cardInfo.card.firmwareVersion.stringValue,
            baseCurrency: baseCurrency,
            userWalletId: userWalletId
        )
    }
}

extension LockedUserWalletModel: UserWalletSerializable {
    func serialize() -> StoredUserWallet {
        userWallet
    }
}
