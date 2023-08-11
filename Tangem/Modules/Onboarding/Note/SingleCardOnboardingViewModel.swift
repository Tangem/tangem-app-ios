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
    @Published var isCardScanned: Bool = true

    override var disclaimerModel: DisclaimerViewModel? {
        guard currentStep == .disclaimer else { return nil }

        return super.disclaimerModel
    }

    override var navbarTitle: String {
        currentStep.navbarTitle
    }

    override var subtitle: String? {
        if currentStep == .topup,
           case .xrp = cardModel?.walletModels.first?.blockchainNetwork.blockchain {
            return Localization.onboardingTopUpBodyNoAccountError("10", "XRP")
        } else {
            return super.subtitle
        }
    }

    override var mainButtonTitle: String {
        if case .topup = currentStep, !canBuyCrypto {
            return Localization.onboardingButtonReceiveCrypto
        }

        return super.mainButtonTitle
    }

    override var mainButtonSettings: MainButton.Settings? {
        switch currentStep {
        case .disclaimer:
            return nil
        default:
            return super.mainButtonSettings
        }
    }

    override var isSupplementButtonVisible: Bool {
        switch currentStep {
        case .topup:
            return currentStep.isSupplementButtonVisible && canBuyCrypto
        default:
            return currentStep.isSupplementButtonVisible
        }
    }

    override var supplementButtonColor: ButtonColorStyle {
        switch currentStep {
        case .disclaimer:
            return .black
        default:
            return super.supplementButtonColor
        }
    }

    var isCustomContentVisible: Bool {
        switch currentStep {
        case .saveUserWallet, .disclaimer:
            return true
        default:
            return false
        }
    }

    var isButtonsVisible: Bool {
        switch currentStep {
        case .saveUserWallet: return false
        default: return true
        }
    }

    var infoText: String? {
        currentStep.infoText
    }

    private var previewUpdateCounter: Int = 0
    private var walletCreatedWhileOnboarding: Bool = false
    private var scheduledUpdate: DispatchWorkItem?

    private var canBuyCrypto: Bool {
        if let blockchain = cardModel?.walletModels.first?.blockchainNetwork.blockchain,
           exchangeService.canBuy(blockchain.currencySymbol, amountType: .coin, blockchain: blockchain) {
            return true
        }

        return false
    }

    override init(input: OnboardingInput, coordinator: OnboardingCoordinator) {
        super.init(input: input, coordinator: coordinator)

        if case .singleWallet(let steps) = input.steps {
            self.steps = steps
        } else {
            fatalError("Wrong onboarding steps passed to initializer")
        }

        if let walletModel = cardModel?.walletModels.first {
            updateCardBalanceText(for: walletModel)
        }

        if steps.first == .topup, currentStep == .topup {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.updateCardBalance()
            }
        }

        bind()
    }

    // MARK: Functions

    private func bind() {
        $currentStepIndex
            .removeDuplicates()
            .delay(for: 0.1, scheduler: DispatchQueue.main)
            .receiveValue { [weak self] index in
                guard let self,
                      index < steps.count else { return }

                let currentStep = steps[index]

                switch currentStep {
                case .topup:
                    if let walletModel = cardModel?.walletModels.first {
                        updateCardBalanceText(for: walletModel)
                    }

                    if walletCreatedWhileOnboarding {
                        return
                    }

                    withAnimation {
                        self.isBalanceRefresherVisible = true
                    }

                    updateCardBalance()
                case .successTopup:
                    withAnimation {
                        self.refreshButtonState = .doneCheckmark
                    }
                    fallthrough
                case .success:
                    fireConfetti()
                default:
                    break
                }
            }
            .store(in: &bag)
    }

    func onAppear() {
        playInitialAnim()
    }

    override func backButtonAction() {
        alert = AlertBuilder.makeExitAlert { [weak self] in
            self?.closeOnboarding()
        }
    }

    override func mainButtonAction() {
        switch currentStep {
        case .disclaimer:
            break
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
            goToNextStep()
        case .saveUserWallet:
            break
        case .success:
            goToNextStep()
        }
    }

    override func supplementButtonAction() {
        switch currentStep {
        case .topup:
            openQR()
        case .disclaimer:
            disclaimerAccepted()
            goToNextStep()
        default:
            break
        }
    }

    override func setupCardsSettings(animated: Bool, isContainerSetup: Bool) {
        switch currentStep {
        case .saveUserWallet:
            mainCardSettings = .zero
            supplementCardSettings = .zero
        default:
            mainCardSettings = .init(
                targetSettings: SingleCardOnboardingCardsLayout.main.cardAnimSettings(
                    for: currentStep,
                    containerSize: containerSize,
                    animated: animated
                ),
                intermediateSettings: nil
            )
            supplementCardSettings = .init(targetSettings: SingleCardOnboardingCardsLayout.supplementary.cardAnimSettings(for: currentStep, containerSize: containerSize, animated: animated), intermediateSettings: nil)
        }
    }

    private func createWallet() {
        guard let cardInitializer = input.cardInitializer else { return }

        AppSettings.shared.cardsStartedActivation.insert(input.cardInput.cardId)
        Analytics.log(.buttonCreateWallet)
        isMainButtonBusy = true

        cardInitializer.initializeCard(mnemonic: nil) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let cardInfo):
                initializeUserWallet(from: cardInfo)
                walletCreatedWhileOnboarding = true

                Analytics.log(.walletCreatedSuccessfully, params: [.creationType: .walletCreationTypePrivateKey])

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.goToNextStep()
                }

            case .failure(let error):
                if !error.toTangemSdkError().isUserCancelled {
                    AppLog.shared.error(error, params: [.action: .createWallet])
                }
            }

            isMainButtonBusy = false
        }
    }
}
