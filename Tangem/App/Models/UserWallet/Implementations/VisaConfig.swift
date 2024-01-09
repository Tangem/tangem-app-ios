//
//  VisaConfig.swift
//  Tangem
//
//  Created by Andrew Son on 13/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct VisaConfig: CardContainer {
    let card: CardDTO

    init(card: CardDTO) {
        self.card = card
    }

    private var defaultBlockchain: Blockchain {
        return .polygon(testnet: false)
    }
}

extension VisaConfig: UserWalletConfig {
    var cardSetLabel: String? {
        nil
    }

    var cardsCount: Int {
        1
    }

    var cardName: String {
        "Tangem Visa"
    }

    var mandatoryCurves: [EllipticCurve] {
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

    var warningEvents: [WarningEvent] {
        WarningEventsFactory().makeWarningEvents(for: card)
    }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: nil)
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var productType: Analytics.ProductType {
        .visa
    }

    var cardHeaderImage: ImageType? {
        // TODO: Update card image when available
        Assets.Cards.noteCardano
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            return .hidden
        case .passcode:
            return .hidden
        case .longTap:
            return card.settings.isRemovingUserCodesAllowed ? .available : .hidden
        case .send:
            return .hidden
        case .longHashes:
            return .hidden
        case .signedHashesCounter:
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
            return .hidden
        case .hdWallets:
            return .hidden
        case .onlineImage:
            return card.firmwareVersion.type == .release ? .available : .hidden
        case .staking:
            return .hidden
        case .topup:
            return .hidden
        case .tokenSynchronization:
            return .hidden
        case .referralProgram:
            return .hidden
        case .swapping:
            return .hidden
        case .displayHashesCount:
            return .hidden
        case .transactionHistory:
            return .hidden
        case .accessCodeRecoverySettings:
            return .hidden
        case .promotion:
            return .hidden
        }
    }

    func makeWalletModelsFactory() -> WalletModelsFactory {
        return CommonWalletModelsFactory(derivationStyle: nil)
    }

    func makeAnyWalletManagerFactory() throws -> AnyWalletManagerFactory {
        return SimpleWalletManagerFactory()
    }
}

extension VisaConfig: VisaCardOnboardingStepsBuilderFactory {}
