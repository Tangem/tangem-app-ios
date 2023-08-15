//
//  UserWalletConfig.swift
//  Tangem
//
//  Created by Alexander Osokin on 29.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

protocol UserWalletConfig: OnboardingStepsBuilderFactory, BackupServiceFactory, TangemSdkFactory {
    var emailConfig: EmailConfig? { get }

    var tou: TOU { get }

    var cardsCount: Int { get }

    var cardSetLabel: String? { get }

    var cardName: String { get }

    var mandatoryCurves: [EllipticCurve] { get }

    var derivationStyle: DerivationStyle? { get }

    var tangemSigner: TangemSigner { get }

    var warningEvents: [WarningEvent] { get }

    var canSkipBackup: Bool { get }

    var canImportKeys: Bool { get }
    /// All blockchains supported by this user wallet.
    var supportedBlockchains: Set<Blockchain> { get }

    /// Blockchains to be added to the tokens list by default on wallet creation.
    var defaultBlockchains: [StorageEntry.V2.Entry] { get }

    /// Blockchains to be added to the tokens list on every scan. E.g. demo blockchains.
    var persistentBlockchains: [StorageEntry.V2.Entry]? { get }

    /// Blockchain which embedded in the card.
    var embeddedBlockchain: StorageEntry.V2.Entry? { get }

    var emailData: [EmailCollectedData] { get }

    var userWalletIdSeed: Data? { get }

    var productType: Analytics.ProductType { get }

    var cardHeaderImage: ImageType? { get }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability

    func makeWalletModelsFactory() -> WalletModelsFactory

    func makeAnyWalletManagerFacrory() throws -> AnyWalletManagerFactory
}

extension UserWalletConfig {
    func hasFeature(_ feature: UserWalletFeature) -> Bool {
        getFeatureAvailability(feature).isAvailable
    }

    func isFeatureVisible(_ feature: UserWalletFeature) -> Bool {
        !getFeatureAvailability(feature).isHidden
    }

    func getDisabledLocalizedReason(for feature: UserWalletFeature) -> String? {
        getFeatureAvailability(feature).disabledLocalizedReason
    }

    var tou: TOU {
        let url = URL(string: "https://tangem.com/tangem_tos.html")!
        return TOU(id: url.absoluteString, url: url)
    }

    var emailConfig: EmailConfig? {
        .default
    }

    var canSkipBackup: Bool {
        true
    }

    var canImportKeys: Bool {
        false
    }

    var derivationStyle: DerivationStyle? {
        return nil
    }
}

struct EmailConfig {
    let recipient: String
    let subject: String

    static var `default`: EmailConfig {
        .init(
            recipient: "support@tangem.com",
            subject: Localization.feedbackSubjectSupportTangem
        )
    }
}

struct TOU {
    let id: String
    let url: URL
}

protocol CardContainer {
    var card: CardDTO { get }
}

extension UserWalletConfig where Self: CardContainer {
    func makeTangemSdk() -> TangemSdk {
        let factory = GenericTangemSdkFactory(isAccessCodeSet: card.isAccessCodeSet)
        return factory.makeTangemSdk()
    }

    func makeBackupService() -> BackupService {
        let factory = GenericBackupServiceFactory(isAccessCodeSet: card.isAccessCodeSet)
        return factory.makeBackupService()
    }
}
