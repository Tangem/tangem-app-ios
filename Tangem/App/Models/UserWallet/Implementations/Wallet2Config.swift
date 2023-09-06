//
//  Wallet2Config.swift
//  Tangem
//
//  Created by Sergey Balashov on 14.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

// TODO: Refactor default/persistent blockchains https://tangem.atlassian.net/browse/IOS-4051
struct Wallet2Config {
    let card: CardDTO
    private let isDemo: Bool

    init(card: CardDTO, isDemo: Bool) {
        self.card = card
        self.isDemo = isDemo
    }
}

extension Wallet2Config: UserWalletConfig {
    var cardSetLabel: String? {
        guard let backupCardsCount = card.backupStatus?.backupCardsCount else {
            return nil
        }

        return Localization.cardLabelCardCount(backupCardsCount + 1)
    }

    var cardsCount: Int {
        if let backupCardsCount = card.backupStatus?.backupCardsCount {
            return backupCardsCount + 1
        } else {
            return 1
        }
    }

    var cardName: String {
        "Wallet"
    }

    var mandatoryCurves: [EllipticCurve] {
        [.secp256k1, .ed25519, .bls12381_G2_AUG, .bip0340, .ed25519_slip0010]
    }

    var derivationStyle: DerivationStyle? {
        return .v3
    }

    var canSkipBackup: Bool {
        if isDemo {
            return true
        }

        return false
    }

    var canImportKeys: Bool {
        card.settings.isKeysImportAllowed && FeatureProvider.isAvailable(.importSeedPhrase)
    }

    var supportedBlockchains: Set<Blockchain> {
        SupportedBlockchains(version: .v2).blockchains()
    }

    var defaultBlockchains: [StorageEntry] {
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
        guard isDemo else {
            return nil
        }

        let blockchainIds = DemoUtil().getDemoBlockchains(isTestnet: AppEnvironment.current.isTestnet)

        let entries: [StorageEntry] = blockchainIds.compactMap { coinId in
            guard let blockchain = supportedBlockchains.first(where: { $0.coinId == coinId }) else {
                return nil
            }

            if let derivationStyle = derivationStyle {
                let derivationPath = blockchain.derivationPath(for: derivationStyle)
                let network = BlockchainNetwork(blockchain, derivationPath: derivationPath)
                return .init(blockchainNetwork: network, tokens: [])
            }

            let network = BlockchainNetwork(blockchain, derivationPath: nil)
            return .init(blockchainNetwork: network, tokens: [])
        }

        return entries
    }

    var embeddedBlockchain: StorageEntry? {
        return nil
    }

    var warningEvents: [WarningEvent] {
        var warnings = WarningEventsFactory().makeWarningEvents(for: card)

        if isDemo, !AppEnvironment.current.isTestnet {
            warnings.append(.demoCard)
        }

        return warnings
    }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: nil)
    }

    var tangemSigner: TangemSigner {
        let shouldSkipCardId = card.backupStatus?.isActive ?? false
        let cardId = shouldSkipCardId ? nil : card.cardId
        return .init(with: cardId, sdk: makeTangemSdk())
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var productType: Analytics.ProductType {
        .wallet2
    }

    var cardHeaderImage: ImageType? {
        cardsCount == 2 ? Assets.Cards.wallet2Double : Assets.Cards.wallet2Triple
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
            return card.settings.isRemovingUserCodesAllowed ? .available : .hidden
        case .send:
            return .available
        case .longHashes:
            return .available
        case .signedHashesCounter:
            return .hidden
        case .backup:
            if isDemo {
                return .demoStub
            }

            if card.settings.isBackupAllowed, card.backupStatus == .noBackup {
                return .available
            }

            return .hidden
        case .twinning:
            return .hidden
        case .exchange:
            if isDemo {
                return .demoStub
            }

            return .available
        case .walletConnect:
            if isDemo {
                return .demoStub
            }

            return .available
        case .multiCurrency:
            return .available
        case .resetToFactory:
            if isDemo {
                return .demoStub
            }

            return .available
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
            return .available
        case .referralProgram:
            if isDemo {
                return .demoStub
            }

            return .available
        case .swapping:
            if isDemo {
                return .demoStub
            }

            return .available
        case .displayHashesCount:
            return .available
        case .transactionHistory:
            return .hidden
        case .accessCodeRecoverySettings:
            return .available
        case .promotion:
            return .available
        }
    }

    func makeWalletModelsFactory() -> WalletModelsFactory {
        if isDemo {
            return DemoWalletModelsFactory(derivationStyle: derivationStyle)
        }

        return CommonWalletModelsFactory(derivationStyle: derivationStyle)
    }

    func makeAnyWalletManagerFactory() throws -> AnyWalletManagerFactory {
        if hasFeature(.hdWallets) {
            return GenericWalletManagerFactory()
        } else {
            return SimpleWalletManagerFactory()
        }
    }
}

// MARK: - WalletOnboardingStepsBuilderFactory

extension Wallet2Config: WalletOnboardingStepsBuilderFactory {}

// MARK: - Private extensions

private extension Card.BackupStatus {
    var backupCardsCount: Int? {
        if case .active(let backupCards) = self {
            return backupCards
        }

        return nil
    }
}

private extension CardDTO {
    var hasImportedWallets: Bool {
        wallets.contains(where: { $0.isImported == true })
    }
}
