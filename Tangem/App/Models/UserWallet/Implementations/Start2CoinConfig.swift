//
//  Start2CoinConfig.swift
//  Tangem
//
//  Created by Alexander Osokin on 01.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct Start2CoinConfig: CardContainer {
    let card: CardDTO
    private let walletData: WalletData

    private var defaultBlockchain: Blockchain {
        Blockchain.from(blockchainName: walletData.blockchain, curve: card.supportedCurves[0])!
    }

    init(card: CardDTO, walletData: WalletData) {
        self.card = card
        self.walletData = walletData
    }
}

extension Start2CoinConfig: UserWalletConfig {
    var emailConfig: EmailConfig? {
        .init(
            recipient: "cardsupport@start2coin.com",
            subject: Localization.feedbackSubjectSupport
        )
    }

    var cardsCount: Int {
        1
    }

    var cardSetLabel: String? {
        nil
    }

    var cardName: String {
        "Start2Coin"
    }

    var createWalletCurves: [EllipticCurve] {
        [.secp256k1]
    }

    var supportedBlockchains: Set<Blockchain> {
        [defaultBlockchain]
    }

    var defaultBlockchains: [StorageEntry] {
        let network = BlockchainNetwork(defaultBlockchain, derivationPath: nil)
        let entry = StorageEntry(blockchainNetwork: network, tokens: [])
        return [entry]
    }

    var persistentBlockchains: [StorageEntry]? {
        return defaultBlockchains
    }

    var embeddedBlockchain: StorageEntry? {
        return defaultBlockchains.first
    }

    var generalNotificationEvents: [GeneralNotificationEvent] {
        GeneralNotificationEventsFactory().makeNotifications(for: card)
    }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: walletData)
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var productType: Analytics.ProductType {
        .start2coin
    }

    var cardHeaderImage: ImageType? {
        Assets.Cards.s2c
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .send:
            return .available
        case .signedHashesCounter:
            if card.firmwareVersion.type == .release {
                return .available
            }

            return .hidden
        case .accessCode:
            return .hidden
        case .passcode:
            return .hidden
        case .longTap:
            return card.settings.isRemovingUserCodesAllowed ? .available : .hidden
        case .longHashes:
            return .hidden
        case .backup:
            return .hidden
        case .twinning:
            return .hidden
        case .exchange:
            return .hidden
        case .walletConnect:
            return .hidden
        case .multiCurrency:
            return .hidden
        case .resetToFactory:
            return .hidden
        case .receive:
            return .available
        case .withdrawal:
            return .available
        case .hdWallets:
            return .hidden
        case .onlineImage:
            return card.firmwareVersion.type == .release ? .available : .hidden
        case .staking:
            return .hidden
        case .topup:
            return .available
        case .tokenSynchronization:
            return .hidden
        case .referralProgram:
            return .hidden
        case .swapping:
            return .hidden
        case .displayHashesCount:
            return .available
        case .transactionHistory:
            return .hidden
        case .accessCodeRecoverySettings:
            return .hidden
        case .promotion:
            return .hidden
        }
    }

    func makeOnboardingStepsBuilder(
        backupService: BackupService,
        isPushNotificationsAvailable: Bool
    ) -> OnboardingStepsBuilder {
        return Start2CoinOnboardingStepsBuilder(
            hasWallets: !card.wallets.isEmpty,
            isPushNotificationsAvailable: isPushNotificationsAvailable
        )
    }

    func makeWalletModelsFactory(userWalletId: UserWalletId) -> WalletModelsFactory {
        return CommonWalletModelsFactory(config: self, userWalletId: userWalletId)
    }

    func makeAnyWalletManagerFactory() throws -> AnyWalletManagerFactory {
        return SimpleWalletManagerFactory()
    }
}
