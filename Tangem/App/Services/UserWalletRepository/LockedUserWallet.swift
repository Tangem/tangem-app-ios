//
//  LockedUserWallet.swift
//  Tangem
//
//  Created by Alexander Osokin on 31.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class LockedUserWallet: UserWalletModel {
    let walletModelsManager: WalletModelsManager = LockedWalletModelsManager()
    let userTokenListManager: UserTokenListManager = LockedUserTokenListManager()
    let userTokensManager: UserTokensManager = LockedUserTokensManager()
    let config: UserWalletConfig
    var signer: TangemSigner

    var tokensCount: Int? { nil }

    var cardsCount: Int { config.cardsCount }

    var isMultiWallet: Bool { config.hasFeature(.multiCurrency) }

    var userWalletId: UserWalletId { .init(value: userWallet.userWalletId) }

    var updatePublisher: AnyPublisher<Void, Never> { .just }

    var emailData: [EmailCollectedData] {
        var data = config.emailData

        let userWalletIdItem = EmailCollectedData(type: .card(.userWalletId), data: userWalletId.stringValue)
        data.append(userWalletIdItem)

        return data
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

    let backupInput: OnboardingInput? = nil
    let twinInput: OnboardingInput? = nil

    private(set) var userWallet: UserWallet
    private let cardImageProvider = CardImageProvider()

    init(with userWallet: UserWallet) {
        self.userWallet = userWallet
        config = UserWalletConfigFactory(userWallet.cardInfo()).makeConfig()
        signer = TangemSigner(filter: .cardId(""), sdk: .init(), twinKey: nil)
    }

    func initialUpdate() {}

    func updateWalletName(_ name: String) {
        // Renaming locked wallets is prohibited
    }

    func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalanceProvider.TotalBalance>, Never> {
        .just(output: .loaded(.init(balance: 0, currencyCode: "", hasError: false)))
    }
}

extension LockedUserWallet: MainHeaderInfoProvider {
    var isUserWalletLocked: Bool { true }

    var userWalletNamePublisher: AnyPublisher<String, Never> {
        .just(output: userWallet.name)
    }

    var cardHeaderImagePublisher: AnyPublisher<ImageType?, Never> {
        .just(output: config.cardHeaderImage)
    }

    var isTokensListEmpty: Bool { false }
}

extension LockedUserWallet: AnalyticsContextDataProvider {
    func getAnalyticsContextData() -> AnalyticsContextData? {
        let cardInfo = userWallet.cardInfo()
        let embeddedEntry = config.embeddedBlockchain
        let baseCurrency = embeddedEntry?.tokens.first?.symbol ?? embeddedEntry?.blockchainNetwork.blockchain.currencySymbol

        return AnalyticsContextData(
            id: nil,
            productType: config.productType,
            batchId: cardInfo.card.batchId,
            firmware: cardInfo.card.firmwareVersion.stringValue,
            baseCurrency: baseCurrency
        )
    }
}
