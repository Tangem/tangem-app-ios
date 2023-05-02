//
//  SaltPayConfig.swift
//  Tangem
//
//  Created by Alexander Osokin on 08.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct SaltPayConfig: CardContainer {
    let card: CardDTO

    init(card: CardDTO) {
        self.card = card
    }

    private var defaultBlockchain: Blockchain {
        GnosisRegistrator.Settings.main.blockchain
    }

    private var defaultToken: Token {
        GnosisRegistrator.Settings.main.token
    }
}

extension SaltPayConfig: UserWalletConfig {
    var emailConfig: EmailConfig? {
        return nil
    }

    var tou: TOU {
        let url = URL(string: "https://tangem.com/soltpay_tos.html")!
        return TOU(id: url.absoluteString, url: url)
    }

    var cardsCount: Int {
        1
    }

    var cardSetLabel: String? {
        nil
    }

    var cardName: String {
        "SaltPay"
    }

    var defaultCurve: EllipticCurve? {
        defaultBlockchain.curve
    }

    var canSkipBackup: Bool {
        false
    }

    var supportedBlockchains: Set<Blockchain> {
        [defaultBlockchain]
    }

    var defaultBlockchains: [StorageEntry] {
        let network = BlockchainNetwork(defaultBlockchain, derivationPath: nil)
        let entry = StorageEntry(blockchainNetwork: network, tokens: [defaultToken])
        return [entry]
    }

    var persistentBlockchains: [StorageEntry]? {
        defaultBlockchains
    }

    var embeddedBlockchain: StorageEntry? {
        defaultBlockchains.first
    }

    var warningEvents: [WarningEvent] {
        WarningEventsFactory().makeWarningEvents(for: card)
    }

    var tangemSigner: TangemSigner { .init(with: card.cardId, sdk: makeTangemSdk()) }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: nil)
    }

    var cardAmountType: Amount.AmountType? {
        .token(value: defaultToken)
    }

    var supportChatEnvironment: SupportChatEnvironment {
        .saltPay
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var exchangeServiceEnvironment: ExchangeServiceEnvironment {
        .saltpay
    }

    var productType: Analytics.ProductType {
        SaltPayUtil().isBackupCard(cardId: card.cardId) ? .visaBackup : .visa
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .transactionHistory:
            return .available
        default:
            return .hidden
        }
    }

    func makeWalletModel(for token: StorageEntry) throws -> WalletModel {
        let blockchain = token.blockchainNetwork.blockchain

        guard let walletPublicKey = card.wallets.first(where: { $0.curve == blockchain.curve })?.publicKey else {
            throw CommonError.noData
        }

        let factory = WalletModelFactory()
        return try factory.makeSingleWallet(
            walletPublicKey: walletPublicKey,
            blockchain: blockchain,
            token: token.tokens.first,
            derivationStyle: card.derivationStyle
        )
    }

    func makeOnboardingStepsBuilder(backupService: BackupService) -> OnboardingStepsBuilder {
        return SaltPayOnboardingStepsBuilder(
            card: card,
            touId: tou.id,
            backupService: backupService
        )
    }

    func makeBackupService() -> BackupService {
        let factory = SaltPayBackupServiceFactory(cardId: card.cardId, isAccessCodeSet: card.isAccessCodeSet)
        return factory.makeBackupService()
    }

    func makeTangemSdk() -> TangemSdk {
        return SaltPayTangemSdkFactory(isAccessCodeSet: card.isAccessCodeSet).makeTangemSdk()
    }
}
