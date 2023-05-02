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
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published var firstTwinImage: Image?
    @Published var secondTwinImage: Image?
    @Published var currentCardIndex: Int = 0
    @Published var displayTwinImages: Bool = false
    @Published var alertAccepted: Bool = false

    var retwinMode: Bool = false

    override var disclaimerModel: DisclaimerViewModel? {
        guard currentStep == .disclaimer else { return nil }

        return super.disclaimerModel
    }

    override var navbarTitle: String {
        currentStep.navbarTitle
    }

    override var title: String? {
        if !isInitialAnimPlayed {
            return super.title
        }

        if twinCardSeries.number != 1 {
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

    override var mainButtonTitle: String {
        if !isInitialAnimPlayed {
            return super.mainButtonTitle
        }

        if twinCardSeries.number != 1 {
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
            return Localization.onboardingButtonReceiveCrypto
        }

        return super.mainButtonTitle
    }

    override var supplementButtonColor: ButtonColorStyle {
        switch currentStep {
        case .disclaimer:
            return .black
        default:
            return super.supplementButtonColor
        }
    }

    override var isSupplementButtonVisible: Bool {
        switch currentStep {
        case .topup:
            return currentStep.isSupplementButtonVisible && canBuy
        default:
            return currentStep.isSupplementButtonVisible
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

    override var mainButtonSettings: MainButton.Settings? {
        var settings = super.mainButtonSettings

        switch currentStep {
        case .disclaimer:
            return nil
        case .alert:
            settings?.isDisabled = !alertAccepted
        default: break
        }

        return settings
    }

    private var stackCalculator: StackCalculator = .init()
    private var twinCardSeries: TwinCardSeries
    private var stepUpdatesSubscription: AnyCancellable?
    private let twinsService: TwinsWalletCreationUtil

    private var canBuy: Bool { exchangeService.canBuy("BTC", amountType: .coin, blockchain: .bitcoin(testnet: false)) }

    override init(input: OnboardingInput, coordinator: OnboardingCoordinator) {
        let twinData = input.twinData!

        twinCardSeries = twinData.series
        twinsService = .init(cardId: input.cardInput.cardId, twinData: twinData)

        super.init(input: input, coordinator: coordinator)

        if let walletModel = cardModel?.walletModels.first {
            updateCardBalanceText(for: walletModel)
        }

        if case .twins(let steps) = input.steps {
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

    func onAppear() {
        if isInitialAnimPlayed {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playInitialAnim()
        }
    }

    override func setupContainer(with size: CGSize) {
        stackCalculator.setup(for: size, with: .init(
            topCardSize: TwinOnboardingCardLayout.first.frame(for: .first, containerSize: size),
            topCardOffset: .init(width: 0, height: 0.06 * size.height),
            cardsVerticalOffset: 20,
            scaleStep: 0.14,
            opacityStep: 0.65,
            numberOfCards: 2,
            maxCardsInStack: 2
        ))
        super.setupContainer(with: size)
    }

    override func playInitialAnim(includeInInitialAnim: (() -> Void)? = nil) {
        Analytics.log(.twinningScreenOpened)
        super.playInitialAnim {
            self.displayTwinImages = true
        }
    }

    override func onOnboardingFinished(for cardId: String) {
        super.onOnboardingFinished(for: cardId)

        // remove pair cid
        if let pairCardId = twinsService.twinPairCardId {
            AppSettings.shared.cardsStartedActivation.remove(pairCardId)
        }
    }

    override func mainButtonAction() {
        switch currentStep {
        case .disclaimer:
            break
        case .intro:
            fallthrough
        case .done, .success, .alert:
            goToNextStep()
        case .first:
            if !retwinMode, let cardId = cardModel?.cardId {
                AppSettings.shared.cardsStartedActivation.insert(cardId)
            }

            Analytics.log(.twinSetupStarted)

            // TODO: Remove?
            if case .first = twinsService.step.value {} else {
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
        case .saveUserWallet:
            break
        }
    }

    override func supplementButtonAction() {
        switch currentStep {
        case .topup:
            withAnimation {
                openQR()
            }
        case .disclaimer:
            disclaimerAccepted()
            goToNextStep()
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
            alert = AlertBuilder.makeOkGotItAlert(message: Localization.onboardingTwinExitWarning)
        default:
            alert = AlertBuilder.makeExitAlert { [weak self] in
                guard let self else { return }

                // This part is related only to the twin cards, because for other card types
                // reset to factory settings goes not through onboarding screens. If back button
                // appearance logic will change in future - recheck also this code and update it accordingly
                if self.isOnboardingFinished {
                    self.onboardingDidFinish()
                } else {
                    self.closeOnboarding()
                }
            }
        }
    }

    private func bind() {
        twinsService
            .isServiceBusy
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isServiceBudy in
                self?.isMainButtonBusy = isServiceBudy
            }
            .store(in: &bag)

        $currentStepIndex
            .removeDuplicates()
            .delay(for: 0.1, scheduler: DispatchQueue.main)
            .receiveValue { [weak self] index in
                guard let steps = self?.steps,
                      index < steps.count else { return }

                let currentStep = steps[index]

                switch currentStep {
                case .done, .success:
                    withAnimation {
                        self?.refreshButtonState = .doneCheckmark
                        self?.fireConfetti()
                    }
                default:
                    break
                }
            }
            .store(in: &bag)
    }

    private func subscribeToStepUpdates() {
        stepUpdatesSubscription = twinsService.step
            .receive(on: DispatchQueue.main)
            .combineLatest(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
            .sink(receiveValue: { [unowned self] newStep, _ in
                switch (self.currentStep, newStep) {
                case (.first, .second):
                    if let originalUserWallet = self.input.userWalletToDelete {
                        userWalletRepository.delete(originalUserWallet, logoutIfNeeded: false)
                    }
                    fallthrough
                case (.second, .third), (.third, .done):
                    if case .done(let cardInfo) = newStep {
                        self.initializeUserWallet(from: cardInfo)
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
                    AppLog.shared.debug("Wrong state while twinning cards: current - \(self.currentStep), new - \(newStep)")
                }

                if !retwinMode {
                    if let pairCardId = twinsService.twinPairCardId {
                        AppSettings.shared.cardsStartedActivation.insert(pairCardId)
                    }

                    if let userWalletId = self.cardModel?.userWalletId {
                        self.analyticsContext.updateContext(with: userWalletId)
                        Analytics.logTopUpIfNeeded(balance: 0)
                    }
                }
            })
    }

    private func loadSecondTwinImage() {
        CardImageProvider()
            .loadTwinImage(for: twinCardSeries.pair.number)
            .map { $0.image }
            .zip($cardImage.compactMap { $0 })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] paired, main in
                guard let self = self else { return }

                self.firstTwinImage = main
                self.secondTwinImage = paired
            }
            .store(in: &bag)
    }
}
