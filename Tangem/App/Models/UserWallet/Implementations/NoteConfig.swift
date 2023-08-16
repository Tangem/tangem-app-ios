//
//  NoteConfig.swift
//  Tangem
//
//  Created by Alexander Osokin on 01.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct NoteConfig: CardContainer {
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

extension NoteConfig: UserWalletConfig {
    var cardSetLabel: String? {
        nil
    }

    var cardsCount: Int {
        1
    }

    var cardName: String {
        "Note"
    }

    var mandatoryCurves: [EllipticCurve] {
        [defaultBlockchain.curve]
    }

    var supportedBlockchains: Set<Blockchain> {
        [defaultBlockchain]
    }

    var defaultBlockchains: [StorageEntry.V3.Entry] {
        let network = BlockchainNetwork(defaultBlockchain, derivationPath: nil)
        let converter = StorageEntriesConverter()

        return [converter.convert(network)]
    }

    var persistentBlockchains: [StorageEntry.V3.Entry]? {
        return defaultBlockchains
    }

    var embeddedBlockchains: [StorageEntry.V3.Entry]? {
        return defaultBlockchains
    }

    var warningEvents: [WarningEvent] {
        WarningEventsFactory().makeWarningEvents(for: card)
    }

    var tangemSigner: TangemSigner { .init(with: card.cardId, sdk: makeTangemSdk()) }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: noteData)
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var productType: Analytics.ProductType {
        .note
    }

    var cardHeaderImage: ImageType? {
        switch defaultBlockchain {
        case .bitcoin: return Assets.Cards.noteBitcoin
        case .ethereum: return Assets.Cards.noteEthereum
        case .cardano: return Assets.Cards.noteCardano
        case .bsc: return Assets.Cards.noteBinance
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
            return card.settings.isRemovingUserCodesAllowed ? .available : .hidden
        case .send:
            return .available
        case .longHashes:
            return .hidden
        case .signedHashesCounter:
            if card.firmwareVersion.type == .release {
                return .available
            }

            return .hidden
        case .backup:
            return .hidden
        case .twinning:
            return .hidden
        case .exchange:
            return .available
        case .walletConnect:
            return .hidden
        case .multiCurrency:
            return .hidden
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

    func makeWalletModelsFactory() -> WalletModelsFactory {
        return CommonWalletModelsFactory(derivationStyle: nil)
    }

    func makeAnyWalletManagerFacrory() throws -> AnyWalletManagerFactory {
        return SimpleWalletManagerFactory()
    }
}

// MARK: - NoteCardOnboardingStepsBuilderFactory

extension NoteConfig: NoteCardOnboardingStepsBuilderFactory {}
