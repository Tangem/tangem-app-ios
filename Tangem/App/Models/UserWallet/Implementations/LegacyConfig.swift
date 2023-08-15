//
//  LegacyConfig.swift
//  Tangem
//
//  Created by Alexander Osokin on 01.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

/// V3 Config
struct LegacyConfig: CardContainer {
    let card: CardDTO
    private let walletData: WalletData?

    private var defaultBlockchain: Blockchain? {
        guard let walletData = walletData else { return nil }

        return Blockchain.from(blockchainName: walletData.blockchain, curve: card.supportedCurves[0])
    }

    private var isMultiwallet: Bool {
        card.supportedCurves.contains(.secp256k1)
    }

    private var defaultToken: BlockchainSdk.Token? {
        guard let token = walletData?.token else { return nil }

        return .init(
            name: token.name,
            symbol: token.symbol,
            contractAddress: token.contractAddress,
            decimalCount: token.decimals
        )
    }

    init(card: CardDTO, walletData: WalletData?) {
        self.card = card
        self.walletData = walletData
    }
}

extension LegacyConfig: UserWalletConfig {
    var cardSetLabel: String? {
        nil
    }

    var cardsCount: Int {
        1
    }

    var cardName: String {
        "Tangem Card"
    }

    var mandatoryCurves: [EllipticCurve] {
        if let defaultBlockchain {
            return [defaultBlockchain.curve]
        }

        // old white multiwallet
        if card.settings.maxWalletsCount > 1 {
            return [.secp256k1, .ed25519]
        }

        // should not be the case
        return []
    }

    var supportedBlockchains: Set<Blockchain> {
        if isMultiwallet || defaultBlockchain == nil {
            let allBlockchains = SupportedBlockchains(version: .v1).blockchains()
            return allBlockchains.filter { card.walletCurves.contains($0.curve) }
        } else {
            return [defaultBlockchain!]
        }
    }

    var defaultBlockchains: [StorageEntry.V3.Entry] {
        let converter = StorageEntriesConverter()

        if let defaultBlockchain = defaultBlockchain {
            let network = BlockchainNetwork(defaultBlockchain, derivationPath: nil)

            return [
                converter.convert(network),
                defaultToken.map { converter.convert($0, in: network) },
            ].compactMap { $0 }
        } else {
            guard isMultiwallet else { return [] }

            let isTestnet = AppEnvironment.current.isTestnet
            let blockchains = [
                Blockchain.bitcoin(testnet: isTestnet),
                Blockchain.ethereum(testnet: isTestnet),
            ]

            return blockchains.map { converter.convert(.init($0)) }
        }
    }

    var persistentBlockchains: [StorageEntry.V3.Entry]? {
        if isMultiwallet {
            return nil
        }

        return defaultBlockchains
    }

    var embeddedBlockchain: StorageEntry.V3.Entry? {
        return defaultBlockchains.first
    }

    var warningEvents: [WarningEvent] {
        var warnings = WarningEventsFactory().makeWarningEvents(for: card)

        if !hasFeature(.send) {
            warnings.append(.oldCard)
        }

        if card.firmwareVersion.doubleValue < 2.28,
           NFCUtils.isPoorNfcQualityDevice {
            warnings.append(.oldDeviceOldCard)
        }

        return warnings
    }

    var tangemSigner: TangemSigner { .init(with: card.cardId, sdk: makeTangemSdk()) }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: walletData)
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var productType: Analytics.ProductType {
        .other
    }

    var cardHeaderImage: ImageType? {
        if walletData == nil {
            let multiWalletWhiteBatch = "CB79"
            let devKitBatch = "CB83"

            switch card.batchId {
            case multiWalletWhiteBatch:
                return Assets.Cards.multiWalletWhite
            case devKitBatch:
                return Assets.Cards.developer
            default:
                break
            }
        }

        return nil
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            return .disabled()
        case .passcode:
            return .disabled()
        case .longTap:
            return card.settings.isRemovingUserCodesAllowed ? .available : .hidden
        case .send:
            if card.firmwareVersion.doubleValue >= 2.28
                || card.settings.securityDelay <= 15000 {
                return .available
            }

            return .disabled()
        case .longHashes:
            return .hidden
        case .signedHashesCounter:
            if card.firmwareVersion.type != .release {
                return .hidden
            } else {
                return .available
            }
        case .backup:
            return .hidden
        case .twinning:
            return .hidden
        case .exchange:
            return .available
        case .walletConnect, .multiCurrency:
            if isMultiwallet {
                return .available
            } else {
                return .hidden
            }
        case .resetToFactory:
            if card.wallets.contains(where: { $0.settings.isPermanent }) {
                return .hidden
            }

            return .available
        case .receive:
            return .available
        case .withdrawal:
            return .available
        case .hdWallets:
            return .hidden
        case .onlineImage:
            return card.firmwareVersion.type == .release ? .available : .hidden
        case .staking:
            return .available
        case .topup:
            return .available
        case .tokenSynchronization, .swapping:
            return isMultiwallet ? .available : .hidden
        case .referralProgram:
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

    func makeWalletModelsFactory() -> WalletModelsFactory {
        return CommonWalletModelsFactory(derivationStyle: nil)
    }

    func makeAnyWalletManagerFacrory() throws -> AnyWalletManagerFactory {
        return SimpleWalletManagerFactory()
    }
}

// MARK: - SingleCardOnboardingStepsBuilderFactory

extension LegacyConfig: SingleCardOnboardingStepsBuilderFactory {}
