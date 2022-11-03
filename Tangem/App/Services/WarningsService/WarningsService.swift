//
//  WarningsService.swift
//  Tangem
//
//  Created by Andrew Son on 22/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine
import BlockchainSdk
import SwiftUI

class WarningsService {
    @Injected(\.rateAppService) var rateAppChecker: RateAppService

    var warningsUpdatePublisher: CurrentValueSubject<Void, Never> = .init(())

    private var mainWarnings: WarningsContainer = .init()
    private var sendWarnings: WarningsContainer = .init()
    private var bag: Set<AnyCancellable> = []

    init() {}

    deinit {
        print("WarningsService deinit")
    }
}

extension WarningsService: AppWarningsProviding {
    func setupWarnings(
        for config: UserWalletConfig,
        card: Card,
        validator: SignatureCountValidator?
    ) {
        setupWarnings(for: config, card: card)

        // The testnet card shouldn't count hashes
        if !AppEnvironment.current.isTestnet {
            validateHashesCount(config: config, card: card, validator: validator)
        }
    }

    func warnings(for location: WarningsLocation) -> WarningsContainer {
        switch location {
        case .main:
            return mainWarnings
        case .send:
            return sendWarnings
        case .manageTokens:
            fatalError("not implemented")
        }
    }

    func appendWarning(for event: WarningEvent) {
        let warning = event.warning
        if event.locationsToDisplay.contains(.main) {
            mainWarnings.add(warning)
        }
        if event.locationsToDisplay.contains(.send) {
            sendWarnings.add(warning)
        }

        warningsUpdatePublisher.send(())
    }

    func hideWarning(_ warning: AppWarning) {
        mainWarnings.remove(warning)
        sendWarnings.remove(warning)
    }

    func hideWarning(for event: WarningEvent) {
        mainWarnings.removeWarning(for: event)
        sendWarnings.removeWarning(for: event)
    }
}

private extension WarningsService {
    func setupWarnings(for config: UserWalletConfig, card: Card) {
        let main = WarningsContainer()
        let send = WarningsContainer()

        var warningEvents = config.warningEvents

        if card.firmwareVersion.type == .sdk && card.isDevelopmentCard && !warningEvents.contains(.testnetCard) {
            warningEvents.append(.devCard)
        }

        for warningEvent in warningEvents  {
            if warningEvent.locationsToDisplay.contains(WarningsLocation.main) {
                main.add(warningEvent.warning)
            }

            if warningEvent.locationsToDisplay.contains(WarningsLocation.send) {
                send.add(warningEvent.warning)
            }
        }

        if rateAppChecker.shouldShowRateAppWarning {
            Analytics.log(.displayRateAppWarning)
            main.add(WarningEvent.rateApp.warning)
        }

        mainWarnings = main
        sendWarnings = send
        warningsUpdatePublisher.send(())
    }

    func validateHashesCount(
        config: UserWalletConfig,
        card: Card,
        validator: SignatureCountValidator?
    ) {
        let cardId = card.cardId
        let cardSignedHashes = card.walletSignedHashes
        let isMultiWallet = config.hasFeature(.multiCurrency)
        let canCountHashes = config.hasFeature(.signedHashesCounter)

        func didFinishCountingHashes() {
            print("⚠️ Hashes counted")
        }

        guard !AppSettings.shared.validatedSignedHashesCards.contains(cardId) else {
            didFinishCountingHashes()
            return
        }

        guard cardSignedHashes > 0 else {
            AppSettings.shared.validatedSignedHashesCards.append(cardId)
            didFinishCountingHashes()
            return
        }

        guard !isMultiWallet else {
            showAlertAnimated(.multiWalletSignedHashes)
            didFinishCountingHashes()
            return
        }

        guard canCountHashes else {
            AppSettings.shared.validatedSignedHashesCards.append(cardId)
            didFinishCountingHashes()
            return
        }

        guard let validator = validator else {
            showAlertAnimated(.numberOfSignedHashesIncorrect)
            didFinishCountingHashes()
            return
        }

        validator.validateSignatureCount(signedHashes: cardSignedHashes)
            .subscribe(on: DispatchQueue.global())
            .receive(on: RunLoop.main)
            .handleEvents(receiveCancel: {
                print("⚠️ Hash counter subscription cancelled")
            })
            .receiveCompletion { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    self?.showAlertAnimated(.numberOfSignedHashesIncorrect)
                }
                didFinishCountingHashes()
            }
            .store(in: &bag)
    }

    func showAlertAnimated(_ event: WarningEvent) {
        withAnimation {
            appendWarning(for: event)
        }
    }
}
