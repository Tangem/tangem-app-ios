//
//  NoteDemoConfig.swift
//  Tangem
//
//  Created by Alexander Osokin on 01.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct NoteDemoConfig: CardContainer {
    let card: CardDTO
    private let noteData: WalletData

    init(card: CardDTO, noteData: WalletData) {
        self.card = card
        self.noteData = noteData
    }

    private var defaultBlockchain: Blockchain {
        let blockchainName = noteData.blockchain.lowercased() == "binance" ? "bsc" : noteData.blockchain
        let defaultBlockchain = Blockchain.from(blockchainName: blockchainName, curve: .secp256k1)!
        return defaultBlockchain
    }
}

extension NoteDemoConfig: UserWalletConfig {
    var cardSetLabel: String? {
        nil
    }

    var cardsCount: Int {
        1
    }

    var cardName: String {
        "Note"
    }

    var createWalletCurves: [EllipticCurve] {
        [defaultBlockchain.curve]
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
        var notifications = GeneralNotificationEventsFactory().makeNotifications(for: card)

        if !AppEnvironment.current.isTestnet {
            notifications.append(.demoCard)
        }

        return notifications
    }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: noteData)
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var productType: Analytics.ProductType {
        .demoNote
    }

    var cardHeaderImage: ImageType? {
        switch defaultBlockchain {
        case .bitcoin: return Assets.Cards.noteBitcoin
        case .ethereum: return Assets.Cards.noteEthereum
        case .cardano: return Assets.Cards.noteCardano
        case .binance: return Assets.Cards.noteBinance
        case .dogecoin: return Assets.Cards.noteDoge
        case .xrp: return Assets.Cards.noteXrp
        default: return nil
        }
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            return .hidden
        case .passcode:
            return .hidden
        case .longTap:
            return .hidden
        case .send:
            return .available
        case .longHashes:
            return .hidden
        case .signedHashesCounter:
            return .hidden
        case .backup:
            return .hidden
        case .twinning:
            return .hidden
        case .exchange:
            return .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
        case .walletConnect:
            return .hidden
        case .multiCurrency:
            return .hidden
        case .resetToFactory:
            return .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
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

    func makeWalletModelsFactory(userWalletId: UserWalletId) -> WalletModelsFactory {
        return DemoWalletModelsFactory(config: self, userWalletId: userWalletId)
    }

    func makeAnyWalletManagerFactory() throws -> AnyWalletManagerFactory {
        return SimpleWalletManagerFactory()
    }
}

// MARK: - NoteCardOnboardingStepsBuilderFactory

extension NoteDemoConfig: NoteCardOnboardingStepsBuilderFactory {}
