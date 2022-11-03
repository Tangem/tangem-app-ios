//
//  OnboardingViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 03/08/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk
import Combine
import BlockchainSdk

class SingleCardOnboardingViewModel: OnboardingTopupViewModel<SingleCardOnboardingStep, OnboardingCoordinator>, ObservableObject {
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository

    @Published var isCardScanned: Bool = true

    override var currentStep: SingleCardOnboardingStep {
        guard currentStepIndex < steps.count else {
            return .welcome
        }

        return steps[currentStepIndex]
    }

    override var subtitle: LocalizedStringKey? {
        if currentStep == .topup,
           case .xrp = cardModel?.walletModels.first?.blockchainNetwork.blockchain {
            return "onboarding_topup_subtitle_xrp"
        } else {
            return super.subtitle
        }
    }

    override var mainButtonTitle: LocalizedStringKey {
        if case .topup = currentStep, !canBuyCrypto {
            return "onboarding_button_receive_crypto"
        }

        return super.mainButtonTitle
    }

    override var isSupplementButtonVisible: Bool {
        switch currentStep {
        case .topup:
            return currentStep.isSupplementButtonVisible && canBuyCrypto
        default:
            return currentStep.isSupplementButtonVisible
        }
    }

    private var previewUpdateCounter: Int = 0
    private var walletCreatedWhileOnboarding: Bool = false
    private var scheduledUpdate: DispatchWorkItem?

    private var canBuyCrypto: Bool {
        if let blockchain = cardModel?.wallets.first?.blockchain,
           exchangeService.canBuy(blockchain.currencySymbol, amountType: .coin, blockchain: blockchain) {
            return true
        }

        return false
    }

    override init(input: OnboardingInput, coordinator: OnboardingCoordinator) {
        super.init(input: input, coordinator: coordinator)

        if case let .singleWallet(steps) = input.steps {
            self.steps = steps
        } else {
            fatalError("Wrong onboarding steps passed to initializer")
        }

        if let walletModel = self.cardModel?.walletModels.first {
            updateCardBalanceText(for: walletModel)
        }

        if steps.first == .topup && currentStep == .topup {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.updateCardBalance()
            }
        }
    }

    // MARK: Functions

    override func backButtonAction() {
        alert = AlertBuilder.makeExitAlert() { [weak self] in
            self?.closeOnboarding()
        }
    }

    override func goToNextStep() {
        super.goToNextStep()
        stepUpdate()
    }

    override func mainButtonAction() {
        switch currentStep {
        case .welcome:
            fallthrough
        case .createWallet:
            createWallet()
        case .topup:
            if canBuyCrypto {
                if let disabledLocalizedReason = cardModel?.getDisabledLocalizedReason(for: .exchange) {
                    alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason) {
                        DispatchQueue.main.async {
                            self.updateCardBalance()
                        }
                    }
                } else {
                    openCryptoShopIfPossible()
                }
            } else {
                supplementButtonAction()
            }
        case .successTopup:
            fallthrough
        case .success:
            goToNextStep()
        }
    }

    override func supplementButtonAction() {
        switch currentStep {
        case .topup:
            openQR()
        default:
            break
        }
    }

    override func setupCardsSettings(animated: Bool, isContainerSetup: Bool) {
        mainCardSettings = .init(targetSettings: SingleCardOnboardingCardsLayout.main.cardAnimSettings(for: currentStep,
                                                                                                       containerSize: containerSize,
                                                                                                       animated: animated),
                                 intermediateSettings: nil)
        supplementCardSettings = .init(targetSettings: SingleCardOnboardingCardsLayout.supplementary.cardAnimSettings(for: currentStep, containerSize: containerSize, animated: animated), intermediateSettings: nil)
    }

    private func createWallet() {
        guard let cardModel else { return }

        isMainButtonBusy = true

        var subscription: AnyCancellable? = nil

        subscription = Deferred {
            Future { (promise: @escaping Future<Void, Error>.Promise) in
                cardModel.createWallet { result in
                    switch result {
                    case .success:
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .combineLatest(NotificationCenter.didBecomeActivePublisher)
        .first()
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.isMainButtonBusy = false
                print("Failed to create wallet. \(error)")
            }
            subscription.map { _ = self?.bag.remove($0) }
        } receiveValue: { [weak self] (_, _) in
            guard let self = self else { return }

            self.cardModel?.appendDefaultBlockchains()

            if case let .singleWallet(steps) = self.input.steps, steps.contains(.topup) {
                if let cardId = self.cardModel?.cardId {
                    AppSettings.shared.cardsStartedActivation.insert(cardId)
                }

                Analytics.log(.onboardingStarted)
            }

            self.cardModel?.userWalletModel?.updateAndReloadWalletModels()
            self.walletCreatedWhileOnboarding = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isMainButtonBusy = false
                self.goToNextStep()
            }
        }

        subscription?.store(in: &bag)
    }

    private func stepUpdate() {
        switch currentStep {
        case .topup:
            if let walletModel = self.cardModel?.walletModels.first {
                updateCardBalanceText(for: walletModel)
            }

            if walletCreatedWhileOnboarding {
                return
            }

            withAnimation {
                isBalanceRefresherVisible = true
            }

            updateCardBalance()
        case .successTopup:
            withAnimation {
                refreshButtonState = .doneCheckmark
            }
            fallthrough
        case .success:
            fireConfetti()
        default:
            break
        }
    }
}
