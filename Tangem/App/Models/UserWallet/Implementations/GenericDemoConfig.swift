//
//  GenericDemoConfig.swift
//  Tangem
//
//  Created by Alexander Osokin on 01.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct GenericDemoConfig: CardContainer {
    let card: CardDTO

    init(card: CardDTO) {
        self.card = card
    }
}

extension GenericDemoConfig: UserWalletConfig {
    var cardSetLabel: String? {
        guard let backupCardsCount = card.backupStatus?.backupCardsCount else {
            return nil
        }

        return Localization.cardLabelCardCount(backupCardsCount + 1)
    }

    var cardsCount: Int {
        1
    }

    var mandatoryCurves: [EllipticCurve] {
        [.secp256k1, .ed25519, .bip0340, .bls12381_G2_AUG]
    }

    var derivationStyle: DerivationStyle? {
        guard hasFeature(.hdWallets) else {
            return nil
        }

        let batchId = card.batchId.uppercased()
        if BatchId.isDetached(batchId) {
            return .v1
        }

        return .v2
    }

    var cardName: String {
        "Wallet"
    }

    var supportedBlockchains: Set<Blockchain> {
        let allBlockchains = SupportedBlockchains(version: .v1).blockchains()
        return allBlockchains.filter { card.walletCurves.contains($0.curve) }
    }

    var defaultBlockchains: [StorageEntry] {
        if let persistentBlockchains = persistentBlockchains {
            return persistentBlockchains
        }

        let isTestnet = AppEnvironment.current.isTestnet
        let blockchains: [Blockchain] = [.ethereum(testnet: isTestnet), .bitcoin(testnet: isTestnet)]

        let entries: [StorageEntry] = blockchains.map {
            if let derivationStyle = derivationStyle {
                let derivationPath = $0.derivationPath(for: derivationStyle)
                let network = BlockchainNetwork($0, derivationPath: derivationPath)
                return .init(blockchainNetwork: network, tokens: [])
            }

            let network = BlockchainNetwork($0, derivationPath: nil)
            return .init(blockchainNetwork: network, tokens: [])
        }

        return entries
    }

    var persistentBlockchains: [StorageEntry]? {
        let blockchains = DemoUtil().getDemoBlockchains(isTestnet: AppEnvironment.current.isTestnet)

        let entries: [StorageEntry] = blockchains.map {
            if let derivationStyle = derivationStyle {
                let derivationPath = $0.derivationPath(for: derivationStyle)
                let network = BlockchainNetwork($0, derivationPath: derivationPath)
                return .init(blockchainNetwork: network, tokens: [])
            }

            let network = BlockchainNetwork($0, derivationPath: nil)
            return .init(blockchainNetwork: network, tokens: [])
        }

        return entries
    }

    var embeddedBlockchain: StorageEntry? {
        return nil
    }

    var warningEvents: [WarningEvent] {
        var warnings = WarningEventsFactory().makeWarningEvents(for: card)

        if !AppEnvironment.current.isTestnet {
            warnings.append(.demoCard)
        }

        return warnings
    }

    var tangemSigner: TangemSigner {
        .init(with: card.cardId, sdk: makeTangemSdk())
    }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: nil)
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var productType: Analytics.ProductType {
        card.firmwareVersion.doubleValue >= 4.39 ? .demoWallet : .other
    }

    var cardHeaderImage: ImageType? {
        Assets.Cards.wallet
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            if card.settings.isSettingAccessCodeAllowed {
                return .available
            }

            return .disabled()
        case .passcode:
            return .hidden
        case .longTap:
            return .hidden
        case .send:
            return .available
        case .longHashes:
            if card.firmwareVersion.doubleValue >= 4.52 {
                return .available
            }

            return .hidden
        case .signedHashesCounter:
            return .hidden
        case .backup:
            return .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
        case .twinning:
            return .hidden
        case .exchange:
            return .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
        case .walletConnect:
            return .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
        case .multiCurrency:
            return .available
        case .resetToFactory:
            return .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
        case .receive:
            return .available
        case .withdrawal:
            return .available
        case .hdWallets:
            return card.settings.isHDWalletAllowed ? .available : .hidden
        case .onlineImage:
            return card.firmwareVersion.type == .release ? .available : .hidden
        case .staking:
            return .available
        case .topup:
            return .available
        case .tokenSynchronization:
            return .hidden
        case .referralProgram:
            return .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
        case .swapping:
            return .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
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

    func makeWalletModelsFactory() -> WalletModelsFactory {
        return DemoWalletModelsFactory(derivationStyle: derivationStyle)
    }

    func makeAnyWalletManagerFacrory() throws -> AnyWalletManagerFactory {
        if hasFeature(.hdWallets) {
            return HDWalletManagerFactory()
        } else {
            return SimpleWalletManagerFactory()
        }
    }
}

// MARK: - WalletOnboardingStepsBuilderFactory

extension GenericDemoConfig: WalletOnboardingStepsBuilderFactory {}

// MARK: - Private extensions

private extension Card.BackupStatus {
    var backupCardsCount: Int? {
        if case .active(let backupCards) = self {
            return backupCards
        }

        return nil
    }
}
