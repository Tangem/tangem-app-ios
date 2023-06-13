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
    @Injected(\.deprecationService) var deprecationService: DeprecationServicing

    private let featureStorage = FeatureStorage()

    private let warningsUpdateSubject = PassthroughSubject<Void, Never>()

    private var mainWarnings: WarningsContainer = .init()
    private var sendWarnings: WarningsContainer = .init()

    private var testnetSubscription: AnyCancellable?

    init() {
        bind()
    }

    deinit {
        AppLog.shared.debug("WarningsService deinit")
    }

    private func bind() {
        if AppEnvironment.current.isProduction {
            return
        }

        testnetSubscription = featureStorage.$isTestnet
            .sink { [weak self] isTestnet in
                if isTestnet {
                    self?.appendWarning(for: .testnetCard)
                } else {
                    self?.hideWarning(for: .testnetCard)
                }
            }
    }
}

extension WarningsService {
    var warningsUpdatePublisher: AnyPublisher<Void, Never> { warningsUpdateSubject.eraseToAnyPublisher() }

    func setupWarnings(
        for config: UserWalletConfig,
        card: CardDTO,
        validator: SignatureCountValidator?
    ) {
        setupWarnings(for: config)

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
    func appendWarning(for event: WarningEvent) {
        let warning = event.warning
        if event.locationsToDisplay.contains(.main) {
            mainWarnings.add(warning)
        }
        if event.locationsToDisplay.contains(.send) {
            sendWarnings.add(warning)
        }
    }

    func setupWarnings(for config: UserWalletConfig) {
        let main = WarningsContainer()
        let send = WarningsContainer()

        let deprecationWarnings = deprecationService.deprecationWarnings
        for warningEvent in deprecationWarnings + config.warningEvents {
            if warningEvent.locationsToDisplay.contains(WarningsLocation.main) {
                main.add(warningEvent.warning)
            }

            if warningEvent.locationsToDisplay.contains(WarningsLocation.send) {
                send.add(warningEvent.warning)
            }
        }

        mainWarnings = main
        sendWarnings = send
        warningsUpdateSubject.send(())
    }

    func validateHashesCount(
        config: UserWalletConfig,
        card: CardDTO,
        validator: SignatureCountValidator?
    ) {
        let cardId = card.cardId
        let cardSignedHashes = card.walletSignedHashes
        let isMultiWallet = config.hasFeature(.multiCurrency)
        let canCountHashes = config.hasFeature(.signedHashesCounter)

        func didFinishCountingHashes() {
            AppLog.shared.debug("⚠️ Hashes counted")
        }

        guard !AppSettings.shared.validatedSignedHashesCards.contains(cardId) else {
            didFinishCountingHashes()
            return
        }

        guard canCountHashes else {
            AppSettings.shared.validatedSignedHashesCards.append(cardId)
            didFinishCountingHashes()
            return
        }

        guard cardSignedHashes > 0 else {
            AppSettings.shared.validatedSignedHashesCards.append(cardId)
            didFinishCountingHashes()
            return
        }

        guard !isMultiWallet else {
            showWarningWithAnimation(.multiWalletSignedHashes)
            didFinishCountingHashes()
            return
        }

        guard let validator = validator else {
            showWarningWithAnimation(.numberOfSignedHashesIncorrect)
            didFinishCountingHashes()
            return
        }

        var validatorSubscription: AnyCancellable?

        validatorSubscription = validator.validateSignatureCount(signedHashes: cardSignedHashes)
            .subscribe(on: DispatchQueue.global())
            .receive(on: RunLoop.main)
            .handleEvents(receiveCancel: {
                AppLog.shared.debug("⚠️ Hash counter subscription cancelled")
            })
            .receiveCompletion { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    self?.showWarningWithAnimation(.numberOfSignedHashesIncorrect)
                }
                didFinishCountingHashes()

                validatorSubscription = nil
            }
    }

    func showWarningWithAnimation(_ event: WarningEvent) {
        withAnimation {
            appendWarning(for: event)
        }
    }
}
