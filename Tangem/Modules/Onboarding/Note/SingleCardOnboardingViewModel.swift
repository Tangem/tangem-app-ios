//
//  SingleCardOnboardingViewModel.swift
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

    override var navbarTitle: String {
        currentStep.navbarTitle
    }

    override var subtitle: String? {
        if currentStep == .topup,
           case .xrp = userWalletModel?.walletModelsManager.walletModels.first?.blockchainNetwork.blockchain {
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
        case .pushNotifications, .createWallet, .successTopup, .success:
            return nil
        default:
            return super.mainButtonSettings
        }
    }

    override var supplementButtonStyle: MainButton.Style {
        switch currentStep {
        case .createWallet, .successTopup, .success:
            return .primary
        default:
            return super.supplementButtonStyle
        }
    }

    override var supplementButtonIcon: MainButton.Icon? {
        if let icon = currentStep.supplementButtonIcon {
            return .trailing(icon)
        }

        return nil
    }

    var isCustomContentVisible: Bool {
        switch currentStep {
        case .saveUserWallet, .pushNotifications, .addTokens:
            return true
        default:
            return false
        }
    }

    override var isSupportButtonVisible: Bool {
        switch currentStep {
        case .success, .successTopup:
            return false
        default:
            return true
        }
    }

    var infoText: String? {
        currentStep.infoText
    }

    private var previewUpdateCounter: Int = 0
    private var walletCreatedWhileOnboarding: Bool = false
    private var scheduledUpdate: DispatchWorkItem?

    private var canBuyCrypto: Bool {
        if let blockchain = userWalletModel?.walletModelsManager.walletModels.first?.blockchainNetwork.blockchain,
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

        if let walletModel = userWalletModel?.walletModelsManager.walletModels.first {
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
                    if let walletModel = userWalletModel?.walletModelsManager.walletModels.first {
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
        case .pushNotifications, .createWallet, .saveUserWallet, .success, .successTopup, .addTokens:
            break
        case .topup:
            if canBuyCrypto {
                if let disabledLocalizedReason = userWalletModel?.config.getDisabledLocalizedReason(for: .exchange) {
                    alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason) {
                        DispatchQueue.main.async {
                            self.updateCardBalance()
                        }
                    }
                } else {
                    openBuyCrypto()
                }
            } else {
                supplementButtonAction()
            }
        }
    }

    override func supplementButtonAction() {
        switch currentStep {
        case .topup:
            openQR()
        case .createWallet:
            createWallet()
        case .successTopup, .success:
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

        AppSettings.shared.cardsStartedActivation.insert(input.primaryCardId)
        Analytics.log(.buttonCreateWallet)
        isMainButtonBusy = true

        cardInitializer.initializeCard(mnemonic: nil, passphrase: nil) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let cardInfo):
                initializeUserWallet(from: cardInfo)
                walletCreatedWhileOnboarding = true

                Analytics.log(.walletCreatedSuccessfully, params: [.creationType: .walletCreationTypePrivateKey])

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.goToNextStep()
                }

            case .failure(let error) where error.toTangemSdkError().isUserCancelled:
                // Do nothing
                break
            case .failure(let error):
                AppLogger.error(error: error)
                Analytics.error(error: error, params: [.action: .createWallet])
                alert = error.alertBinder
            }

            isMainButtonBusy = false
        }
    }
}
