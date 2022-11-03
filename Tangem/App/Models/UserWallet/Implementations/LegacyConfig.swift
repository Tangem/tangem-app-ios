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
struct LegacyConfig {
    private let card: Card
    private let walletData: WalletData?

    private var defaultBlockchain: Blockchain? {
        guard let walletData = walletData else { return nil }

        return Blockchain.from(blockchainName: walletData.blockchain, curve: card.supportedCurves[0])!
    }

    private var isMultiwallet: Bool {
        card.supportedCurves.contains(.secp256k1)
    }

    private var defaultToken: BlockchainSdk.Token? {
        guard let token = walletData?.token else { return nil }

        return .init(name: token.name,
                     symbol: token.symbol,
                     contractAddress: token.contractAddress,
                     decimalCount: token.decimals)
    }

    init(card: Card, walletData: WalletData?) {
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

    var defaultCurve: EllipticCurve? {
        defaultBlockchain?.curve
    }

    var onboardingSteps: OnboardingSteps {
        if card.wallets.isEmpty {
            return .singleWallet([.createWallet, .success])
        }

        return .singleWallet([])
    }

    var backupSteps: OnboardingSteps? {
        nil
    }

    var supportedBlockchains: Set<Blockchain> {
        if isMultiwallet || defaultBlockchain == nil {
            let allBlockchains = AppEnvironment.current.isTestnet ? Blockchain.supportedTestnetBlockchains
                : Blockchain.supportedBlockchains

            return allBlockchains.filter { card.supportedCurves.contains($0.curve) }
        } else {
            return [defaultBlockchain!]
        }
    }

    var defaultBlockchains: [StorageEntry] {
        guard let defaultBlockchain = defaultBlockchain else { return [] }

        let network = BlockchainNetwork(defaultBlockchain, derivationPath: nil)
        let tokens = defaultToken.map { [$0] } ?? []
        let entry = StorageEntry(blockchainNetwork: network, tokens: tokens)
        return [entry]
    }

    var persistentBlockchains: [StorageEntry]? {
        return nil
    }

    var embeddedBlockchain: StorageEntry? {
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

    var tangemSigner: TangemSigner { .init(with: card.cardId) }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: walletData)
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            return .disabled()
        case .passcode:
            return .disabled()
        case .longTap:
            return card.settings.isResettingUserCodesAllowed ? .available : .hidden
        case .send:
            if card.firmwareVersion.doubleValue >= 2.28
                || card.settings.securityDelay <= 15000 {
                return .available
            }

            return .disabled()
        case .longHashes:
            return .hidden
        case .signedHashesCounter:
            if isMultiwallet || card.firmwareVersion.type != .release {
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
        case .walletConnect, .multiCurrency, .tokensSearch:
            if isMultiwallet {
                return .available
            } else {
                return .hidden
            }
        case .resetToFactory:
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
        case .tokenSynchronization:
            if isMultiwallet {
                return .available
            } else {
                return .hidden
            }
        }
    }

    func makeWalletModel(for token: StorageEntry) throws -> WalletModel {
        let factory = WalletModelFactory()

        if isMultiwallet {
            let walletPublicKeys: [EllipticCurve: Data] = card.wallets.reduce(into: [:]) { partialResult, cardWallet in
                partialResult[cardWallet.curve] = cardWallet.publicKey
            }

            return try factory.makeMultipleWallet(walletPublicKeys: walletPublicKeys,
                                                  entry: token,
                                                  derivationStyle: card.derivationStyle)
        } else {
            let blockchain = token.blockchainNetwork.blockchain

            guard let walletPublicKey = card.wallets.first(where: { $0.curve == blockchain.curve })?.publicKey else {
                throw CommonError.noData
            }

            return try factory.makeSingleWallet(walletPublicKey: walletPublicKey,
                                                blockchain: blockchain,
                                                token: token.tokens.first,
                                                derivationStyle: card.derivationStyle)
        }
    }
}
