//
//  WalletOnboardingViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 22.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk
import BlockchainSdk

class WalletOnboardingViewModel: OnboardingTopupViewModel<WalletOnboardingStep, OnboardingCoordinator>, ObservableObject {
    @Injected(\.backupServiceProvider) private var backupServiceProvider: BackupServiceProviding
    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding
    @Injected(\.saltPayRegistratorProvider) private var saltPayRegistratorProvider: SaltPayRegistratorProviding

    @Published var thirdCardSettings: AnimatedViewSettings = .zero
    @Published var canDisplayCardImage: Bool = false
    @Published var pinText: String = ""

    private var stackCalculator: StackCalculator = .init()
    private var fanStackCalculator: FanStackCalculator = .init()
    private var accessCode: String?
    private var cardIds: [String]?
    private var stepPublisher: AnyCancellable?
    private var prepareTask: PreparePrimaryCardTask?
    private var claimed: Bool = false

    private var cardIdDisplayFormat: CardIdDisplayFormat {
        isSaltPayOnboarding ? .none : .lastMasked(4)
    }

    private var isSaltPayOnboarding: Bool {
        saltPayRegistratorProvider.registrator != nil
    }

    //    override var isBackButtonVisible: Bool {
    //        switch currentStep {
    //        case .success: return false
    //        default: return super.isBackButtonVisible
    //        }
    //    }

    override var disclaimerModel: DisclaimerViewModel? {
        guard currentStep == .disclaimer else { return nil }

        return super.disclaimerModel
    }

    override var navbarTitle: String {
        currentStep.navbarTitle
    }

    override var title: String? {
        switch currentStep {
        case .selectBackupCards:
            switch backupCardsAddedCount {
            case 0: return isSaltPayOnboarding ? Localization.onboardingSaltpayTitleNoBackupCard : Localization.onboardingTitleNoBackupCards
            case 1: return isSaltPayOnboarding ? Localization.onboardingSaltpayTitleOneBackupCard : Localization.onboardingTitleOneBackupCard
            default: return Localization.onboardingTitleTwoBackupCards
            }
        case .backupIntro:
            return ""
        case .backupCards:
            switch backupServiceState {
            case .finalizingPrimaryCard: return isSaltPayOnboarding ? Localization.onboardingSaltpayTitlePrepareOrigin : Localization.commonOriginCard
            case .finalizingBackupCard(let index): return isSaltPayOnboarding ? Localization.onboardingSaltpayTitleBackupCard : Localization.onboardingTitleBackupCardFormat(index)
            default: break
            }

        case .registerWallet, .kycStart, .kycRetry, .enterPin, .kycWaiting:
            return nil
        case .claim:
            let claimValue = saltPayRegistratorProvider.registrator?.claimableAmountDescription ?? ""
            return claimed ? Localization.onboardingTitleClaimProgress : Localization.onboardingTitleClaim(claimValue)
        default: break
        }
        return super.title
    }

    override var subtitle: String? {
        switch currentStep {
        case .selectBackupCards:
            switch backupCardsAddedCount {
            case 0: return isSaltPayOnboarding ? Localization.onboardingSaltpaySubtitleNoBackupCards : Localization.onboardingSubtitleNoBackupCards
            case 1: return isSaltPayOnboarding ? Localization.onboardingSaltpaySubtitleOneBackupCard : Localization.onboardingSubtitleOneBackupCard
            default: return Localization.onboardingSubtitleTwoBackupCards
            }
        case .backupIntro:
            return ""
        case .success:
            switch backupCardsAddedCount {
            case 0: return Localization.onboardingSubtitleSuccessTangemWalletOnboarding
            case 1: return Localization.onboardingSubtitleSuccessBackupOneCard
            default: return Localization.onboardingSubtitleSuccessBackup
            }
        case .backupCards:
            switch backupServiceState {
            case .finalizingPrimaryCard:
                if isSaltPayOnboarding {
                    return Localization.onboardingTwinsInterruptWarning
                }

                guard let primaryCardId = backupService.primaryCard?.cardId,
                      let cardIdFormatted = CardIdFormatter(style: cardIdDisplayFormat).string(from: primaryCardId) else {
                    return super.subtitle
                }

                return Localization.onboardingSubtitleScanPrimaryCardFormat(cardIdFormatted)
            case .finalizingBackupCard(let index):
                if isSaltPayOnboarding {
                    return Localization.onboardingTwinsInterruptWarning
                }

                let cardId = backupService.backupCardIds[index - 1]
                guard let cardIdFormatted = CardIdFormatter(style: cardIdDisplayFormat).string(from: cardId) else {
                    return super.subtitle
                }

                return Localization.onboardingSubtitleScanBackupCardFormat(cardIdFormatted)
            default: return super.subtitle
            }
        case .registerWallet, .kycStart, .kycRetry, .enterPin, .kycWaiting:
            return nil
        case .claim:
            return claimed ? Localization.onboardingSubtitleClaimProgress : super.subtitle
        default: return super.subtitle
        }
    }

    override var mainButtonSettings: MainButton.Settings? {
        var icon: MainButton.Icon?

        switch currentStep {
        case .enterPin, .registerWallet, .kycStart, .kycRetry, .kycProgress, .claim, .successClaim, .disclaimer, .kycWaiting, .seedPhraseIntro:
            return nil
        case .selectBackupCards:
            icon = .leading(Assets.plusMini)
        case .createWalletSelector:
            icon = .leading(Assets.tangemIcon)
        case .createWallet:
            icon = .trailing(Assets.tangemIcon)
        default:
            break
        }

        return MainButton.Settings(
            title: mainButtonTitle,
            icon: icon,
            style: mainButtonStyle,
            isLoading: isMainButtonBusy,
            isDisabled: !isMainButtonEnabled,
            action: mainButtonAction
        )
    }

    override var mainButtonTitle: String {
        switch currentStep {
        case .selectBackupCards:
            return Localization.onboardingButtonAddBackupCard
        case .backupCards:
            switch backupServiceState {
            case .finalizingPrimaryCard: return isSaltPayOnboarding ? Localization.onboardingSaltpayButtonBackupOrigin : Localization.onboardingButtonBackupOrigin
            case .finalizingBackupCard(let index): return isSaltPayOnboarding ? Localization.onboardingSaltpayTitleBackupCard : Localization.onboardingButtonBackupCardFormat(index)
            default: break
            }
        case .success:
            return input.isStandalone ? Localization.commonContinue : super.mainButtonTitle
        default: break
        }
        return super.mainButtonTitle
    }

    var mainButtonStyle: MainButton.Style {
        switch currentStep {
        case .selectBackupCards, .kycWaiting: return .secondary
        default: return .primary
        }
    }

    var isMainButtonEnabled: Bool {
        switch currentStep {
        case .selectBackupCards: return canAddBackupCards
        default: return true
        }
    }

    override var isSupplementButtonVisible: Bool {
        if currentStep == .backupIntro {
            if input.isStandalone {
                return false
            }

            if isSaltPayOnboarding {
                return false
            }
        }

        return super.isSupplementButtonVisible
    }

    override var isSupplementButtonEnabled: Bool {
        switch currentStep {
        case .selectBackupCards: return backupCardsAddedCount > 0
        case .claim:
            return saltPayRegistratorProvider.registrator?.canClaim ?? false
        case .enterPin: return pinText.count == SaltPayRegistrator.Constants.pinLength
        default: return true
        }
    }

    override var supplementButtonColor: ButtonColorStyle {
        switch currentStep {
        case .createWalletSelector:
            return .grayAlt3
        case .backupIntro:
            return .transparentWhite
        default:
            return .black
        }
    }

    var infoText: String? {
        currentStep.infoText
    }

    var backupCardsAddedCount: Int {
        return backupService.addedBackupCardsCount
    }

    var isModal: Bool {
        switch (currentStep, backupServiceState) {
        case (.backupCards, .finalizingBackupCard): return true
        default: return false
        }
    }

    var isInfoPagerVisible: Bool {
        switch currentStep {
        case .backupIntro: return true
        default: return false
        }
    }

    var isCustomContentVisible: Bool {
        switch currentStep {
        case .saveUserWallet, .enterPin, .registerWallet, .kycStart, .kycRetry, .kycProgress, .kycWaiting, .disclaimer, .seedPhraseIntro:
            return true
        default: return false
        }
    }

    var isButtonsVisible: Bool {
        switch currentStep {
        case .saveUserWallet, .kycProgress, .seedPhraseIntro: return false
        default: return true
        }
    }

    lazy var kycModel: WebViewContainerViewModel? = {
        guard let registrator = saltPayRegistratorProvider.registrator else { return nil }

        return .init(
            url: registrator.kycURL,
            title: "",
            addLoadingIndicator: false,
            withCloseButton: false,
            withNavigationBar: false,
            urlActions: [registrator.kycDoneURL: { [weak self] _ in
                self?.supplementButtonAction()
            }]
        )
    }()

    var canShowThirdCardImage: Bool {
        !isSaltPayOnboarding
    }

    var canShowOriginCardLabel: Bool {
        if isSaltPayOnboarding {
            return false
        }

        return currentStep == .backupCards
    }

    private var primaryCardStackIndex: Int {
        switch backupServiceState {
        case .finalizingBackupCard(let index):
            return backupCardsAddedCount - index + 1
        default: return 0
        }
    }

    private var firstBackupCardStackIndex: Int {
        switch backupServiceState {
        case .finalizingBackupCard(let index):
            switch index {
            case 1: return 0
            case 2: return 2
            default: return 1
            }
        default: return 1
        }
    }

    private var secondBackupCardStackIndex: Int {
        switch backupServiceState {
        case .finalizingBackupCard(let index):
            return backupCardsAddedCount - index
        default: return 2
        }
    }

    private var canAddBackupCards: Bool {
        if isSaltPayOnboarding {
            return backupService.addedBackupCardsCount == 0
        }

        return backupService.canAddBackupCards
    }

    private var backupServiceState: BackupService.State {
        return backupService.currentState
    }

    @Published private var previewBackupCardsAdded: Int = 0
    @Published private var previewBackupState: BackupService.State = .finalizingPrimaryCard

    private var tangemSdk: TangemSdk { tangemSdkProvider.sdk }
    private var backupService: BackupService { backupServiceProvider.backupService }
    private var saltPayAmountType: Amount.AmountType {
        .token(value: GnosisRegistrator.Settings.main.token)
    }

    override init(input: OnboardingInput, coordinator: OnboardingCoordinator) {
        super.init(input: input, coordinator: coordinator)

        if case .wallet(let steps) = input.steps {
            self.steps = steps
            DispatchQueue.main.async {
                self.fireConfettiIfNeeded()
            }
        }

        if isFromMain {
            canDisplayCardImage = true
        }

        if case .cardId(let cardId) = input.cardInput { // saved backup
            DispatchQueue.main.async {
                self.loadImageForRestoredbackup(cardId: cardId, cardPublicKey: Data())
            }
        }

        bindSaltPayIfNeeded()

        bind()

        if steps.first == .claim, currentStep == .claim {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.onRefresh()
            }
        }
    }

    func onAppear() {
        Analytics.log(.onboardingStarted)

        if isInitialAnimPlayed {
            return
        }

        playInitialAnim()
    }

    func onRefresh() {
        guard let registrator = saltPayRegistratorProvider.registrator else { return }

        updateCardBalance(for: saltPayAmountType, shouldGoToNextStep: !registrator.canClaim)
    }

    private func bind() {
        $currentStepIndex
            .removeDuplicates()
            .delay(for: 0.1, scheduler: DispatchQueue.main)
            .receiveValue { [weak self] index in
                guard let steps = self?.steps,
                      index < steps.count else { return }

                let currentStep = steps[index]

                switch currentStep {
                case .successClaim:
                    withAnimation {
                        self?.refreshButtonState = .doneCheckmark
                        self?.fireConfetti()
                    }
                case .success:
                    withAnimation {
                        self?.fireConfetti()
                    }
                default:
                    break
                }
            }
            .store(in: &bag)
    }

    private func bindSaltPayIfNeeded() {
        guard let saltPayRegistrator = saltPayRegistratorProvider.registrator else { return }

        if let walletModel = cardModel?.walletModels.first {
            updateCardBalanceText(for: walletModel, type: saltPayAmountType)
        }

        if let cardModel = cardModel,
           let backup = cardModel.backupInput, backup.steps.stepsCount > 0,
           !AppSettings.shared.cardsStartedActivation.contains(cardModel.cardId) {
            AppSettings.shared.cardsStartedActivation.insert(cardModel.cardId)
        }

        saltPayRegistrator
            .$error
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.alert, on: self)
            .store(in: &bag)

        saltPayRegistrator
            .$isBusy
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.isSupplementButtonBusy, on: self)
            .store(in: &bag)

        saltPayRegistrator
            .$state
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] newState in
                guard let self else { return }

                guard self.currentStep != .kycRetry else { // we need custom handling
                    return
                }

                switch newState {
                case .kycStart:
                    if self.currentStep == .kycWaiting {
                        if case .wallet(let steps) = self.cardModel?.onboardingInput.steps { // rebuild steps from scratch
                            self.steps = steps
                            self.currentStepIndex = 0
                        }
                        return
                    }

                    self.goToNextStep()
                case .claim:
                    self.goToNextStep()
                case .finished:
                    if self.currentStep != .claim { // move to the next step only after the balance update
                        self.goToNextStep()
                    }
                case .kycRetry:
                    if case .wallet(let steps) = self.cardModel?.onboardingInput.steps { // rebuild steps from scratch
                        self.steps = steps
                        self.currentStepIndex = 0
                    }
                default:
                    break
                }
            })
            .store(in: &bag)
    }

    private func loadImageForRestoredbackup(cardId: String, cardPublicKey: Data) {
        CardImageProvider()
            .loadImage(cardId: cardId, cardPublicKey: cardPublicKey)
            .map { $0.image }
            .weakAssign(to: \.cardImage, on: self)
            .store(in: &bag)
    }

    override func loadImage(supportsOnlineImage: Bool, cardId: String?, cardPublicKey: Data?) {
        super.loadImage(supportsOnlineImage: supportsOnlineImage, cardId: cardId, cardPublicKey: cardPublicKey)
        if !isSaltPayOnboarding {
            secondImage = nil
        } else {
            let isPrimaryScanned = cardId.map { !SaltPayUtil().isBackupCard(cardId: $0) } ?? false
            secondImage = isPrimaryScanned ? Assets.saltPayBackup.image : Assets.saltpay.image
        }
    }

    override func setupContainer(with size: CGSize) {
        stackCalculator.setup(
            for: size,
            with: CardsStackAnimatorSettings(
                topCardSize: WalletOnboardingCardLayout.origin.frame(for: .createWallet, containerSize: size),
                topCardOffset: .init(width: 0, height: 1),
                cardsVerticalOffset: 17,
                scaleStep: 0.11,
                opacityStep: 0.25,
                numberOfCards: 3,
                maxCardsInStack: 3
            )
        )

        let cardSize = WalletOnboardingCardLayout.origin.frame(for: .createWallet, containerSize: size)
        fanStackCalculator.setup(
            for: size,
            with: .init(
                cardsSize: cardSize,
                topCardRotation: 3,
                cardRotationStep: -10,
                topCardOffset: .init(width: 0, height: 0.103 * size.height),
                cardOffsetStep: .init(width: 2, height: -cardSize.height * 0.141),
                scaleStep: 0.07,
                numberOfCards: 3
            )
        )
        super.setupContainer(with: size)
    }

    override func playInitialAnim(includeInInitialAnim: (() -> Void)? = nil) {
        super.playInitialAnim {
            self.canDisplayCardImage = true
        }
    }

    override func goToNextStep() {
        switch currentStep {
        case .createWalletSelector:
            goToStep(.backupIntro)
        default:
            super.goToNextStep()
        }
    }

    override func mainButtonAction() {
        switch currentStep {
        case .createWallet, .createWalletSelector:
            createWallet()
        case .seedPhraseIntro:
            goToNextStep()
        case .scanPrimaryCard:
            readPrimaryCard()
        case .backupIntro:
            if NFCUtils.isPoorNfcQualityDevice {
                alert = AlertBuilder.makeOldDeviceAlert()
            } else {
                if let disabledLocalizedReason = input.cardInput.cardModel?.getDisabledLocalizedReason(for: .backup) {
                    alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
                } else {
                    goToNextStep()
                }
            }
        case .selectBackupCards:
            addBackupCard()
        case .backupCards:
            backupCard()
        case .success:
            goToNextStep()
        default:
            break
        }
    }

    override func supplementButtonAction() {
        switch currentStep {
        case .createWallet:
            break
        case .createWalletSelector:
            goToStep(.seedPhraseIntro)
        case .backupIntro:
            Analytics.log(.backupSkipped)
            if steps.contains(.saveUserWallet) {
                goToStep(.saveUserWallet)
            } else {
                jumpToLatestStep()
            }
        case .selectBackupCards:
            if canAddBackupCards {
                let controller = UIAlertController(title: Localization.commonWarning, message: Localization.onboardingAlertMessageNotMaxBackupCardsAdded, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: Localization.commonContinue, style: .default, handler: { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.openAccessCode()
                    }
                }))
                controller.addAction(UIAlertAction(title: Localization.commonCancel, style: .cancel, handler: { _ in }))
                UIApplication.topViewController?.present(controller, animated: true, completion: nil)
            } else {
                openAccessCode()
            }
        case .kycWaiting:
            saltPayRegistratorProvider.registrator?.update()
        case .enterPin:
            Analytics.log(.onboardingButtonSetPinCode)
            if saltPayRegistratorProvider.registrator?.setPin(pinText) ?? false {
                goToNextStep()
            }
        case .registerWallet:
            Analytics.log(.buttonConnect)
            saltPayRegistratorProvider.registrator?.register()
        case .kycStart:
            goToNextStep()
        case .successClaim:
            goToNextStep()
        case .kycProgress:
            saltPayRegistratorProvider.registrator?.registerKYC()
            goToNextStep()
        case .claim:
            Analytics.log(.buttonClaim)
            claim()
        case .kycRetry:
            saltPayRegistratorProvider.registrator?.update { [weak self] newState in
                guard let self = self else { return }

                switch newState {
                case .kycRetry, .kycStart:
                    self.goToNextStep()
                case .claim:
                    if let index = self.steps.firstIndex(of: .claim) {
                        self.goToStep(with: index)
                    }
                case .finished:
                    if let index = self.steps.firstIndex(of: .success) {
                        self.goToStep(with: index)
                    }
                case .kycWaiting:
                    if let index = self.steps.firstIndex(of: .kycWaiting) {
                        self.goToStep(with: index)
                    }
                default:
                    break
                }
            }
        case .disclaimer:
            disclaimerAccepted()
            goToNextStep()
        default:
            break
        }
    }

    override func setupCardsSettings(animated: Bool, isContainerSetup: Bool) {
        let animated = animated && !isContainerSetup
        switch currentStep {
        case .selectBackupCards:
            mainCardSettings = .init(targetSettings: fanStackCalculator.settingsForCard(at: 0), intermediateSettings: nil)
            var backupCardSettings = fanStackCalculator.settingsForCard(at: 1)
            backupCardSettings.opacity = backupCardsAddedCount >= 1 ? 1 : 0.2

            supplementCardSettings = .init(targetSettings: backupCardSettings, intermediateSettings: nil)
            backupCardSettings = fanStackCalculator.settingsForCard(at: 2)
            backupCardSettings.opacity = backupCardsAddedCount >= 2 ? 1 : 0.2

            thirdCardSettings = .init(targetSettings: backupCardSettings, intermediateSettings: nil)
        case .backupCards:
            let prehideSettings: CardAnimSettings? = backupServiceState == .finalizingPrimaryCard ? nil : stackCalculator.prehideAnimSettings
            mainCardSettings = .init(
                targetSettings: stackCalculator.cardSettings(at: primaryCardStackIndex),
                intermediateSettings: (primaryCardStackIndex == backupCardsAddedCount && animated) ? prehideSettings : nil
            )

            supplementCardSettings = .init(
                targetSettings: stackCalculator.cardSettings(at: firstBackupCardStackIndex),
                intermediateSettings: (firstBackupCardStackIndex == backupCardsAddedCount && animated) ? prehideSettings : nil
            )

            var settings = stackCalculator.cardSettings(at: secondBackupCardStackIndex)
            settings.opacity = backupCardsAddedCount > 1 ? settings.opacity : 0.0
            thirdCardSettings = .init(
                targetSettings: settings,
                intermediateSettings: (backupCardsAddedCount > 1 && secondBackupCardStackIndex == backupCardsAddedCount && animated) ? prehideSettings : nil
            )
        case .saveUserWallet:
            mainCardSettings = .zero
            supplementCardSettings = .zero
            thirdCardSettings = .zero
        default:
            mainCardSettings = WalletOnboardingCardLayout.origin.animSettings(at: currentStep, in: containerSize, fanStackCalculator: fanStackCalculator, animated: animated)
            supplementCardSettings = WalletOnboardingCardLayout.firstBackup.animSettings(at: currentStep, in: containerSize, fanStackCalculator: fanStackCalculator, animated: animated)
            thirdCardSettings = WalletOnboardingCardLayout.secondBackup.animSettings(at: currentStep, in: containerSize, fanStackCalculator: fanStackCalculator, animated: animated)
        }
    }

    func jumpToLatestStep() {
        withAnimation {
            currentStepIndex = steps.count - 1
            setupCardsSettings(animated: true, isContainerSetup: false)
            fireConfetti()
        }
    }

    func claim() {
        guard let saltPayRegistrator = saltPayRegistratorProvider.registrator else { return }

        refreshButtonState = .activityIndicator
        saltPayRegistrator.claim { [weak self] result in
            switch result {
            case .success:
                Analytics.log(.claimFinished)
                self?.claimed = true
                // Add a small delay because of too fast transactions
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self?.onRefresh()
                }
            case .failure:
                self?.resetRefreshButtonState()
            }
        }
    }

    override func backButtonAction() {
        switch currentStep {
        case .backupCards:
            if backupServiceState == .finalizingPrimaryCard {
                fallthrough
            }

            alert = AlertBuilder.makeOkGotItAlert(message: Localization.onboardingBackupExitWarning)
        default:
            alert = AlertBuilder.makeExitAlert { [weak self] in
                self?.back()
            }
        }
    }

    private func back() {
        if isFromMain {
            onboardingDidFinish()
        } else {
            closeOnboarding()
        }

        backupService.discardIncompletedBackup()
    }

    override func handleUserWalletOnFinish() throws {
        if AppSettings.shared.saveAccessCodes,
           let accessCode = accessCode,
           let cardIds = cardIds {
            let accessCodeData: Data = accessCode.sha256()
            let accessCodeRepository = AccessCodeRepository()
            try accessCodeRepository.save(accessCodeData, for: cardIds)
        }

        try super.handleUserWalletOnFinish()
    }

    private func fireConfettiIfNeeded() {
        if currentStep.requiresConfetti {
            fireConfetti()
        }
    }

    private func saveAccessCode(_ code: String) {
        do {
            try backupService.setAccessCode(code)

            accessCode = code
            cardIds = backupService.allCardIds

            saltPayRegistratorProvider.registrator?.setAccessCode(code)

            stackCalculator.setupNumberOfCards(1 + backupCardsAddedCount)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.goToNextStep()
            }
        } catch {
            AppLog.shared.debug("Failed to set access code to backup service")
            AppLog.shared.error(error)
        }
    }

    private func updateStep() {
        switch currentStep {
        case .selectBackupCards:
            setupCardsSettings(animated: true, isContainerSetup: false)
        case .backupCards:
            if backupServiceState == .finished {
                Analytics.log(event: .backupFinished, params: [.cardsCount: String(backupService.addedBackupCardsCount)])
                goToNextStep()
            } else {
                setupCardsSettings(animated: true, isContainerSetup: false)
            }
        default:
            break
        }
    }

    private func createWallet() {
        Analytics.log(.buttonCreateWallet)

        isMainButtonBusy = true
        if !input.isStandalone {
            AppSettings.shared.cardsStartedActivation.insert(input.cardInput.cardId)
        }
        stepPublisher = preparePrimaryCardPublisher()
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .first()
            .mapVoid()
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    AppLog.shared.error(error, params: [.action: .preparePrimary])
                    self?.isMainButtonBusy = false
                case .finished:
                    Analytics.log(.walletCreatedSuccessfully)
                }
                self?.stepPublisher = nil
            }, receiveValue: processPrimaryCardScan)
    }

    private func readPrimaryCard() {
        isMainButtonBusy = true

        stepPublisher = readPrimaryCardPublisher()
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .first()
            .mapVoid()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        AppLog.shared.error(error, params: [.action: .readPrimary])
                        AppLog.shared.debug("Failed to read origin card")
                        AppLog.shared.error(error)
                        self?.isMainButtonBusy = false
                    }
                    self?.stepPublisher = nil
                },
                receiveValue: processPrimaryCardScan
            )
    }

    private func preparePrimaryCardPublisher() -> AnyPublisher<Void, Error> {
        let cardId = input.cardInput.cardId
        let task = PreparePrimaryCardTask()
        prepareTask = task

        return Deferred {
            Future { [weak self] promise in
                guard let self = self else { return }

                self.tangemSdk.startSession(
                    with: task,
                    cardId: cardId,
                    initialMessage: Message(
                        header: nil,
                        body: Localization.initialMessageCreateWalletBody
                    )
                ) { [weak self] result in
                    switch result {
                    case .success(let result):
                        self?.addDefaultTokens(for: result.card)

                        if let cardModel = self?.input.cardInput.cardModel {
                            cardModel.onWalletCreated(result.card)
                        }

                        self?.backupService.setPrimaryCard(result.primaryCard)
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(error))
                    }

                    self?.prepareTask = nil
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func readPrimaryCardPublisher() -> AnyPublisher<Void, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else { return }

                self.backupService.readPrimaryCard(cardId: self.input.cardInput.cardId) { result in
                    switch result {
                    case .success:
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func processPrimaryCardScan() {
        isMainButtonBusy = false
        goToNextStep()
    }

    private func addBackupCard() {
        isMainButtonBusy = true

        stepPublisher =
            Deferred {
                Future { [unowned self] promise in
                    self.backupService.addBackupCard { result in
                        switch result {
                        case .success:
                            promise(.success(()))
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    }
                }
            }
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .first()
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    AppLog.shared.error(error, params: [.action: .addbackup])
                    self?.isMainButtonBusy = false
                }
                self?.stepPublisher = nil
            }, receiveValue: { [weak self] (_: Void, _: Notification) in
                self?.updateStep()
                withAnimation {
                    self?.isMainButtonBusy = false
                }
            })
    }

    private func backupCard() {
        isMainButtonBusy = true

        stepPublisher =
            Deferred {
                Future { [unowned self] promise in
                    self.backupService.proceedBackup { result in
                        switch result {
                        case .success(let updatedCard):
                            if updatedCard.cardId == self.backupService.primaryCard?.cardId {
                                self.input.cardInput.cardModel?.onBackupCreated(updatedCard)
                            } else { // add tokens for backup cards
                                self.addDefaultTokens(for: updatedCard)
                            }

                            promise(.success(()))
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    }
                }
            }
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .first()
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    AppLog.shared.error(error, params: [.action: .proceedBackup])
                    self?.isMainButtonBusy = false
                }
                self?.stepPublisher = nil
            } receiveValue: { [weak self] (_: Void, _: Notification) in
                self?.updateStep()
                withAnimation {
                    self?.isMainButtonBusy = false
                }
            }
    }

    private func previewGoToNextStepDelayed(_ delay: TimeInterval = 2) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.goToNextStep()
            self.isMainButtonBusy = false
        }
    }

    private func addDefaultTokens(for card: Card) {
        let config = UserWalletConfigFactory(CardInfo(card: CardDTO(card: card), walletData: .none, name: "")).makeConfig()

        guard let seed = config.userWalletIdSeed else { return }

        let repository = CommonTokenItemsRepository(key: UserWalletId(with: seed).stringValue)
        repository.append(config.defaultBlockchains)
    }
}

// MARK: - Seed phrase related

extension WalletOnboardingViewModel {
    func openReadMoreAboutSeedPhraseScreen() {
        coordinator.openWebView(with: AppConstants.seedPhraseReadMoreURL)
    }
}

// MARK: - Navigation

extension WalletOnboardingViewModel {
    func openAccessCode() {
        coordinator.openAccessCodeView(callback: saveAccessCode)
    }
}

extension NotificationCenter {
    static var didBecomeActivePublisher: AnyPublisher<Notification, Error> {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

fileprivate extension BackupService {
    var allCardIds: [String] { [primaryCard?.cardId].compactMap { $0 } + backupCardIds }
}
