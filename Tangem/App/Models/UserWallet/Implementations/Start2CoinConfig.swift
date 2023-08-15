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

    var tou: TOU {
        TOUBuilder().makeTOU(for: card.cardId)
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

    var mandatoryCurves: [EllipticCurve] {
        [.secp256k1]
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

    var embeddedBlockchain: StorageEntry.V3.Entry? {
        return defaultBlockchains.first
    }

    var warningEvents: [WarningEvent] {
        WarningEventsFactory().makeWarningEvents(for: card)
    }

    var tangemSigner: TangemSigner { .init(with: card.cardId, sdk: makeTangemSdk()) }

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

    func makeOnboardingStepsBuilder(backupService: BackupService) -> OnboardingStepsBuilder {
        return Start2CoinOnboardingStepsBuilder(hasWallets: !card.wallets.isEmpty, touId: tou.id)
    }

    func makeWalletModelsFactory() -> WalletModelsFactory {
        return CommonWalletModelsFactory(derivationStyle: nil)
    }

    func makeAnyWalletManagerFacrory() throws -> AnyWalletManagerFactory {
        return SimpleWalletManagerFactory()
    }
}

// MARK: - TOU

private struct TOUBuilder {
    func makeTOU(for cardId: String) -> TOU {
        let regionCode = regionCode(for: cardId)
        let url = TOUItem.makeFrom(languageCode: Locale.current.languageCode, regionCode: regionCode).url
        let id = TOUItem.makeFrom(languageCode: nil, regionCode: regionCode).urlString

        return TOU(id: id, url: url)
    }

    private func regionCode(for cardId: String) -> String {
        let cardIdPrefix = cardId[cardId.index(cardId.startIndex, offsetBy: 1)]
        switch cardIdPrefix {
        case "0":
            return "fr"
        case "1":
            return "ch"
        case "2":
            return "at"
        default:
            return "fr"
        }
    }
}

private enum TOUItem: CaseIterable {
    case deAt
    case deCh
    case enCh
    case frCh
    case frFr
    case itCh

    var url: URL { .init(string: urlString)! }

    var urlString: String {
        switch self {
        case .deAt: return "https://tangem.com/start2coin-de-at-tangem.html"
        case .deCh: return "https://tangem.com/start2coin-de-ch-tangem.html"
        case .enCh: return "https://tangem.com/start2coin-en-ch-tangem.html"
        case .frCh: return "https://tangem.com/start2coin-fr-ch-tangem.html"
        case .frFr: return "https://tangem.com/start2coin-fr-fr-tangem.html"
        case .itCh: return "https://tangem.com/start2coin-it-ch-tangem.html"
        }
    }

    var urlStringLegacy: String {
        switch self {
        case .deAt: return "https://app.tangem.com/tou/Start2Coin-de-at-tangem.pdf"
        case .deCh: return "https://app.tangem.com/tou/Start2Coin-de-ch-tangem.pdf"
        case .enCh: return "https://app.tangem.com/tou/Start2Coin-en-ch-tangem.pdf"
        case .frCh: return "https://app.tangem.com/tou/Start2Coin-fr-ch-tangem.pdf"
        case .frFr: return "https://app.tangem.com/tou/Start2Coin-fr-fr-atangem.pdf"
        case .itCh: return "https://app.tangem.com/tou/Start2Coin-it-ch-tangem.pdf"
        }
    }

    static func makeFrom(languageCode: String?, regionCode: String) -> Self {
        switch (languageCode, regionCode) {
        case ("fr", "ch"):
            return .frCh
        case ("de", "ch"):
            return .deCh
        case ("en", "ch"):
            return .enCh
        case ("it", "ch"):
            return .itCh
        case ("fr", "fr"):
            return .frFr
        case ("de", "at"):
            return .deAt
        case (_, "fr"):
            return .frFr
        case (_, "ch"):
            return .enCh
        case (_, "at"):
            return .deAt
        default:
            return .frFr
        }
    }
}

struct S2CTOUMigrator {
    func migrate() {
        var termsOfServicesAccepted = AppSettings.shared.termsOfServicesAccepted

        for tou in TOUItem.allCases {
            if termsOfServicesAccepted.contains(tou.urlStringLegacy) {
                termsOfServicesAccepted.remove(tou.urlStringLegacy)
                termsOfServicesAccepted.append(tou.urlString)
            }
        }

        AppSettings.shared.termsOfServicesAccepted = termsOfServicesAccepted
    }
}
