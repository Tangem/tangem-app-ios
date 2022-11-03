//
//  TwinConfig.swift
//  Tangem
//
//  Created by Alexander Osokin on 01.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct TwinConfig {
    private let card: Card
    private let walletData: WalletData
    private let twinData: TwinData

    private var defaultBlockchain: Blockchain {
        Blockchain.from(blockchainName: walletData.blockchain, curve: card.supportedCurves[0])!
    }

    init(card: Card, walletData: WalletData, twinData: TwinData) {
        self.card = card
        self.walletData = walletData
        self.twinData = twinData
    }
}

extension TwinConfig: UserWalletConfig {
    var sdkConfig: Config {
        var config = TangemSdkConfigFactory().makeDefaultConfig()
        config.cardIdDisplayFormat = .lastLunh(4)
        return config
    }

    var cardSetLabel: String? {
        String.localizedStringWithFormat("card_label_card_count".localized, cardsCount)
    }

    var cardsCount: Int {
        2
    }

    var defaultCurve: EllipticCurve? {
        defaultBlockchain.curve
    }

    var onboardingSteps: OnboardingSteps {
        var steps = [TwinsOnboardingStep]()

        if !AppSettings.shared.isTwinCardOnboardingWasDisplayed { // show intro only once
            AppSettings.shared.isTwinCardOnboardingWasDisplayed = true
            let twinPairNumber = twinData.series.pair.number
            steps.append(.intro(pairNumber: "\(twinPairNumber)"))
        }

        if card.wallets.isEmpty { // twin without created wallet. Start onboarding
            steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
            steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
            return .twins(steps)
        } else { // twin with created wallet
            if twinData.pairPublicKey == nil { // is not twinned
                steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
                steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                return .twins(steps)
            } else { // is twinned
                if AppSettings.shared.cardsStartedActivation.contains(card.cardId) { // card is in onboarding process, go to topup
                    steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                    return .twins(steps)
                } else { // unknown twin, ready to use, go to main
                    return .twins(steps)
                }
            }
        }
    }

    var backupSteps: OnboardingSteps? {
        nil
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
        return nil
    }

    var embeddedBlockchain: StorageEntry? {
        return defaultBlockchains.first
    }

    var warningEvents: [WarningEvent] {
        WarningEventsFactory().makeWarningEvents(for: card)
    }

    // TODO: TBD Enable twin signing by any card
    var tangemSigner: TangemSigner { .init(with: card.cardId) }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: walletData)
    }

    var userWalletIdSeed: Data? {
        TwinCardsUtils.makeCombinedWalletKey(for: card, pairData: twinData)
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            return .hidden
        case .passcode:
            if twinData.pairPublicKey != nil {
                return .available
            }

            return .disabled()
        case .longTap:
            return card.settings.isResettingUserCodesAllowed ? .available : .hidden
        case .send:
            return .available
        case .longHashes:
            return .hidden
        case .signedHashesCounter:
            return .hidden
        case .backup:
            return .hidden
        case .twinning:
            return .available
        case .exchange:
            return .available
        case .walletConnect:
            return .hidden
        case .multiCurrency:
            return .hidden
        case .tokensSearch:
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
            return .available
        case .staking:
            return .available
        case .topup:
            return .available
        case .tokenSynchronization:
            return .hidden
        }
    }

    func makeWalletModel(for token: StorageEntry) throws -> WalletModel {
        guard let savedPairKey = twinData.pairPublicKey,
              let walletPublicKey = card.wallets.first?.publicKey else {
            throw CommonError.noData
        }

        let factory = WalletManagerFactoryProvider().factory
        let twinManager = try factory.makeTwinWalletManager(walletPublicKey: walletPublicKey,
                                                            pairKey: savedPairKey,
                                                            isTestnet: AppEnvironment.current.isTestnet)

        return WalletModel(walletManager: twinManager, derivationStyle: card.derivationStyle)
    }
}
