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

    var createWalletCurves: [EllipticCurve] {
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

    var isWalletsCreated: Bool {
        return !card.wallets.isEmpty
    }

    var canImportKeys: Bool {
        card.settings.isKeysImportAllowed
    }

    var supportedBlockchains: Set<Blockchain> {
        SupportedBlockchains(version: .v2).blockchains()
    }

    var defaultBlockchains: [StorageEntry] {
        let isTestnet = AppEnvironment.current.isTestnet
        let blockchains: [Blockchain] = [
            .bitcoin(testnet: isTestnet),
            .ethereum(testnet: isTestnet),
        ]

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

    var generalNotificationEvents: [GeneralNotificationEvent] {
        var notifications = GeneralNotificationEventsFactory().makeNotifications(for: card)

        if isDemo, !AppEnvironment.current.isTestnet {
            notifications.append(.demoCard)
        }

        return notifications
    }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: nil)
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var productType: Analytics.ProductType {
        return .wallet2
    }

    var cardHeaderImage: ImageType? {
        // Case with broken backup (e.g. CardLinked)
        if cardsCount == 1 {
            return nil
        }

        // Wallet 2.0 cards can't be used without backup, so min number of cards = 2
        // and there can't be more than 3 cards.
        switch card.batchId {
        // Tron 37X cards
        case "AF07":
            return cardsCount == 2 ? Assets.Cards.tronDouble : Assets.Cards.tronTriple
        // Kaspa cards
        case "AF08":
            return cardsCount == 2 ? Assets.Cards.kaspaDouble : Assets.Cards.kaspaTriple
        // BAD Idea cards
        case "AF09":
            return cardsCount == 2 ? Assets.Cards.badIdeaDouble : Assets.Cards.badIdeaTriple
        // Wallet white
        case "AF15":
            return cardsCount == 2 ? Assets.Cards.wallet2WhiteDouble : Assets.Cards.wallet2WhiteTriple
        // Wallet traillant
        case "AF16":
            return cardsCount == 2 ? Assets.Cards.walletTraillantDouble : Assets.Cards.walletTraillantTriple
        // Wallet avrora
        case "AF18":
            return cardsCount == 2 ? Assets.Cards.walletAvroraDouble : Assets.Cards.walletAvroraTriple
        // Wallet JR
        case "AF14":
            return cardsCount == 2 ? Assets.Cards.jrDouble : Assets.Cards.jrTriple
        // Wallet grim
        case "AF13":
            return cardsCount == 2 ? Assets.Cards.grimDouble : Assets.Cards.grimTriple
        // Wallet satoshi friends
        case "AF19":
            return cardsCount == 2 ? Assets.Cards.satoshiFriendsDouble : Assets.Cards.satoshiFriendsTriple
        // New World Elite (NWE)
        case "AF26":
            return cardsCount == 2 ? Assets.Cards.newWorldEliteDouble : Assets.Cards.newWorldEliteTriple
        // Vechain
        case "AF29":
            return cardsCount == 2 ? Assets.Cards.vechainWalletDouble : Assets.Cards.vechainWalletTriple
        // Pizza Day Wallet
        case "AF33":
            return cardsCount == 2 ? Assets.Cards.pizzaDayWalletDouble : Assets.Cards.pizzaDayWalletTriple
        // Red panda
        case "AF34":
            return cardsCount == 2 ? Assets.Cards.redPandaDouble : Assets.Cards.redPandaTriple
        // Cryptoseth
        case "AF32":
            return cardsCount == 2 ? Assets.Cards.cryptosethDouble : Assets.Cards.cryptosethTriple
        // Kishu
        case "AF52":
            return cardsCount == 2 ? Assets.Cards.kishuDouble : Assets.Cards.kishuTriple
        // Baby Doge
        case "AF51":
            return cardsCount == 2 ? Assets.Cards.babyDogeDouble : Assets.Cards.babyDogeTriple
        // TG-COQ
        case "AF28":
            return cardsCount == 2 ? Assets.Cards.tgDouble : Assets.Cards.tgTriple
        // Coin Metrica
        case "AF27":
            return cardsCount == 2 ? Assets.Cards.coinMetricaDouble : Assets.Cards.coinMetricaTriple
        // Volt Inu
        case "AF35":
            return cardsCount == 2 ? Assets.Cards.voltInuDouble : Assets.Cards.voltInuTriple
        // Kaspa 2
        case "AF25", "AF61", "AF72":
            return cardsCount == 2 ? Assets.Cards.kaspa2Double : Assets.Cards.kaspa2Triple
        // Kaspa reseller
        case "AF31":
            return cardsCount == 2 ? Assets.Cards.kaspaResellerDouble : Assets.Cards.kaspaResellerTriple
        // Vivid: Lemon, Aqua, Grapefruit
        case "AF40", "AF41", "AF42", "AF75", "AF76", "AF77":
            return Assets.Cards.lemonAquaGrapefruit
        // Peach, Air, Glass
        case "AF43", "AF44", "AF45", "AF78", "AF79", "AF80":
            return Assets.Cards.peachAirGlass
        // Kaspa Mint
        case "AF73":
            return cardsCount == 2 ? Assets.Cards.kaspaMint2 : Assets.Cards.kaspaMint3
        // BTC Gold
        case "AF71":
            return cardsCount == 2 ? Assets.Cards.btcNew2 : Assets.Cards.btcNew3
        // Stealth wallet
        case "AF60", "AF74", "AF88":
            return cardsCount == 2 ? Assets.Cards.stealthWalletSET2 : Assets.Cards.stealthWalletSET3
        // Crypto Org
        case "AF57":
            return cardsCount == 2 ? Assets.Cards.cryptorgSet2 : Assets.Cards.cryptorgSet3
        // CryptoCasey
        case "AF21", "AF22", "AF23":
            return cardsCount == 2 ? Assets.Cards.cryptoCaseySet2 : Assets.Cards.cryptoCaseySet3
        // Konan
        case "AF93":
            return cardsCount == 2 ? Assets.Cards.konanDouble : Assets.Cards.konanTriple
        // Kaspy
        case "AF95":
            return cardsCount == 2 ? Assets.Cards.kaspyDouble : Assets.Cards.kaspyTriple
        // Kasper
        case "AF96":
            return cardsCount == 2 ? Assets.Cards.kasperDouble : Assets.Cards.kasperTriple
        // BTC365
        case "AF97":
            return cardsCount == 2 ? Assets.Cards.btc365Double : Assets.Cards.btc365Triple
        // Neiro on ETH
        case "AF98":
            return cardsCount == 2 ? Assets.Cards.neiroDouble : Assets.Cards.neiroTriple
        // Winter 2
        case "AF990011", "AF990012", "AF990013":
            return cardsCount == 2 ? Assets.Cards.winter2Double : Assets.Cards.winter2Triple
        // USA
        case "AF91":
            return cardsCount == 2 ? Assets.Cards.usaDouble : Assets.Cards.usaTriple
        // Gets Mine
        case "BB000008":
            return cardsCount == 2 ? Assets.Cards.getsmineDouble : Assets.Cards.getsmineTriple

        // Tangem Wallet 2.0
        default:

            var isUserWalletWithRing = false

            if let userWalletIdSeed {
                let userWalletId = UserWalletId(with: userWalletIdSeed).stringValue
                isUserWalletWithRing = AppSettings.shared.userWalletIdsWithRing.contains(userWalletId)
            }

            if isUserWalletWithRing || RingUtil().isRing(batchId: card.batchId) {
                return cardsCount == 2 ? Assets.Cards.ring1card : Assets.Cards.ring2cards
            }

            return cardsCount == 2 ? Assets.Cards.wallet2Double : Assets.Cards.wallet2Triple
        }
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
            return DemoWalletModelsFactory(config: self)
        }

        return CommonWalletModelsFactory(config: self)
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
