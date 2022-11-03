//
//  TwinsOnboardingViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 26.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class TwinsOnboardingViewModel: OnboardingTopupViewModel<TwinsOnboardingStep, OnboardingCoordinator>, ObservableObject {
    @Published var firstTwinImage: Image?
    @Published var secondTwinImage: Image?
    @Published var pairNumber: String
    @Published var currentCardIndex: Int = 0
    @Published var displayTwinImages: Bool = false
    @Published var alertAccepted: Bool = false

    var retwinMode: Bool = false

    override var currentStep: TwinsOnboardingStep {
        guard currentStepIndex < steps.count else {
            return .welcome
        }

        guard isInitialAnimPlayed else {
            return .welcome
        }

        return steps[currentStepIndex]
    }

    override var title: LocalizedStringKey? {
        if !isInitialAnimPlayed {
            return super.title
        }

        if twinData.series.number != 1 {
            switch currentStep {
            case .first, .third:
                return TwinsOnboardingStep.second.title
            case .second:
                return TwinsOnboardingStep.first.title
            default:
                break
            }
        }

        return super.title
    }

    override var mainButtonTitle: LocalizedStringKey {
        if !isInitialAnimPlayed {
            return super.mainButtonTitle
        }

        if twinData.series.number != 1 {
            switch currentStep {
            case .first, .third:
                return TwinsOnboardingStep.second.mainButtonTitle
            case .second:
                return TwinsOnboardingStep.first.mainButtonTitle
            default:
                break
            }
        }

        if case .topup = currentStep, !canBuy {
            return "onboarding_button_receive_crypto"
        }

        return super.mainButtonTitle
    }

    override var isOnboardingFinished: Bool {
        if case .intro = currentStep, steps.count == 1 {
            return true
        }

        return super.isOnboardingFinished
    }

    override var isSupplementButtonVisible: Bool {
        switch currentStep {
        case .topup:
            return currentStep.isSupplementButtonVisible && canBuy
        default:
            return currentStep.isSupplementButtonVisible
        }
    }

    override var mainButtonSettings: TangemButtonSettings? {
        var settings = super.mainButtonSettings

        switch currentStep {
        case .alert:
            settings?.isEnabled = alertAccepted
        default: break
        }

        return settings
    }

    private var stackCalculator: StackCalculator = .init()
    private var twinData: TwinData
    private var stepUpdatesSubscription: AnyCancellable?
    private let twinsService: TwinsWalletCreationUtil

    private var canBuy: Bool { exchangeService.canBuy("BTC", amountType: .coin, blockchain: .bitcoin(testnet: false)) }

    override init(input: OnboardingInput, coordinator: OnboardingCoordinator) {
        let cardModel = input.cardInput.cardModel!
        let twinData = input.twinData!

        self.pairNumber = "\(twinData.series.pair.number)"
        self.twinData = twinData
        self.twinsService = .init(card: cardModel, twinData: twinData)

        super.init(input: input, coordinator: coordinator)

        if let walletModel = self.cardModel?.walletModels.first {
            updateCardBalanceText(for: walletModel)
        }

        if case let .twins(steps) = input.steps {
            self.steps = steps

            if case .topup = steps.first {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.updateCardBalance()
                }
            }
        }
        if isFromMain {
            displayTwinImages = true
        }

        if case .alert = steps.first {
            retwinMode = true // TODO: fix it
        }

        bind()
        loadSecondTwinImage()
    }

    override func setupContainer(with size: CGSize) {
        stackCalculator.setup(for: size, with: .init(topCardSize: TwinOnboardingCardLayout.first.frame(for: .first, containerSize: size),
                                                     topCardOffset: .init(width: 0, height: 0.06 * size.height),
                                                     cardsVerticalOffset: 20,
                                                     scaleStep: 0.14,
                                                     opacityStep: 0.65,
                                                     numberOfCards: 2,
                                                     maxCardsInStack: 2))
        super.setupContainer(with: size)
    }

    override func playInitialAnim(includeInInitialAnim: (() -> Void)? = nil) {
        Analytics.log(.twinningScreenOpened)
        super.playInitialAnim {
            self.displayTwinImages = true
        }
    }

    override func onOnboardingFinished(for cardId: String) {
        Analytics.log(.twinSetupFinished)
        super.onOnboardingFinished(for: cardId)

        // remove pair cid
        if let pairCardId = twinsService.twinPairCardId {
            super.onOnboardingFinished(for: pairCardId)
        }
    }

    override func mainButtonAction() {
        switch currentStep {
        case .welcome:
            fallthrough
        case .intro:
            fallthrough
        case .done, .success, .alert:
            goToNextStep()
        case .first:
            if !retwinMode {
                if let cardId = cardModel?.cardId {
                    AppSettings.shared.cardsStartedActivation.insert(cardId)
                }
                Analytics.log(.onboardingStarted)
            }

            if twinsService.step.value != .first {
                twinsService.resetSteps()
                stepUpdatesSubscription = nil
            }
            fallthrough
        case .second:
            fallthrough
        case .third:
            isMainButtonBusy = true
            subscribeToStepUpdates()
            twinsService.executeCurrentStep()
        case .topup:
            if canBuy {
                openCryptoShopIfPossible()
            } else {
                supplementButtonAction()
            }
        }
    }

    override func goToNextStep() {
        super.goToNextStep()

        switch currentStep {
        case .done, .success:
            withAnimation {
                refreshButtonState = .doneCheckmark
                fireConfetti()
            }
        default:
            break
        }
    }

    override func supplementButtonAction() {
        switch currentStep {
        case .topup:
            withAnimation {
                openQR()
            }
        default:
            break
        }
    }

    override func setupCardsSettings(animated: Bool, isContainerSetup: Bool) {
        // this condition is needed to prevent animating stack when user is trying to dismiss modal sheet
        mainCardSettings = TwinOnboardingCardLayout.first.animSettings(at: currentStep, containerSize: containerSize, stackCalculator: stackCalculator, animated: animated && !isContainerSetup)
        supplementCardSettings = TwinOnboardingCardLayout.second.animSettings(at: currentStep, containerSize: containerSize, stackCalculator: stackCalculator, animated: animated && !isContainerSetup)
    }

    override func backButtonAction() {
        switch currentStep {
        case .second, .third:
            alert = AlertBuilder.makeOkGotItAlert(message: "onboarding_twin_exit_warning".localized)
        default:
            alert = AlertBuilder.makeExitAlert() { [weak self] in
                guard let self else { return }

                // This part is related only to the twin cards, because for other card types
                // reset to factory settings goes not through onboarding screens. If back button
                // appearance logic will change in future - recheck also this code and update it accordingly
                if self.currentStep.isOnboardingFinished {
                    self.onboardingDidFinish()
                } else {
                    self.closeOnboarding()
                }
            }
        }
    }

    private func bind() {
        Analytics.log(.twinSetupStarted)
        twinsService
            .isServiceBusy
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isServiceBudy in
                self?.isMainButtonBusy = isServiceBudy
            }
            .store(in: &bag)
    }

    private func subscribeToStepUpdates() {
        stepUpdatesSubscription = twinsService.step
            .receive(on: DispatchQueue.main)
            .combineLatest(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
            .sink(receiveValue: { [unowned self] (newStep, _) in
                switch (self.currentStep, newStep) {
                case (.first, .second), (.second, .third), (.third, .done):
                    if newStep == .done {
                        if input.isStandalone {
                            self.fireConfetti()
                        } else {
                            self.updateCardBalance()
                        }
                    }

                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.5)) {
                            self.currentStepIndex += 1
                            self.currentCardIndex = self.currentStep.topTwinCardIndex
                            self.setupCardsSettings(animated: true, isContainerSetup: false)
                        }
                    }
                default:
                    print("Wrong state while twinning cards: current - \(self.currentStep), new - \(newStep)")
                }

                if let pairCardId = twinsService.twinPairCardId,
                   !retwinMode {
                    AppSettings.shared.cardsStartedActivation.insert(pairCardId)
                }
            })
    }

    private func loadSecondTwinImage() {
        CardImageProvider()
            .loadTwinImage(for: twinData.series.pair.number)
            .map { Image(uiImage: $0) }
            .zip($cardImage.compactMap { $0 })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (paired, main) in
                guard let self = self else { return }

                self.firstTwinImage = main
                self.secondTwinImage = paired
                //            withAnimation {
                //                self.displayTwinImages = true
                //            }
            }
            .store(in: &bag)
    }
}
