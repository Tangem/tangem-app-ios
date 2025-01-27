//
//  WalletOnboardingViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 22.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import CombineExt
import TangemSdk
import BlockchainSdk
import TangemFoundation

class WalletOnboardingViewModel: OnboardingViewModel<WalletOnboardingStep, OnboardingCoordinator>, ObservableObject {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let seedPhraseManager = SeedPhraseManager()

    @Published var thirdCardSettings: AnimatedViewSettings = .zero
    @Published var canDisplayCardImage: Bool = false

    var primaryLabel: String {
        if backupService.isPrimaryRing {
            Localization.commonOriginRing
        } else {
            Localization.commonOriginCard
        }
    }

    private var stackCalculator: StackCalculator = .init()
    private var fanStackCalculator: FanStackCalculator = .init()
    private var accessCode: String?
    private var cardIds: [String]?
    private var stepPublisher: AnyCancellable?

    private var cardIdDisplayFormat: CardIdDisplayFormat = .lastMasked(4)

    override var navbarTitle: String {
        currentStep.navbarTitle
    }

    // MARK: - Title settings

    override var title: String? {
        switch currentStep {
        case .selectBackupCards:
            switch backupCardsAddedCount {
            case 0: return Localization.onboardingTitleNoBackupCards
            case 1: return Localization.onboardingTitleOneBackupCard
            default: return Localization.onboardingTitleTwoBackupCards
            }
        case .backupIntro:
            return ""
        case .backupCards:
            switch backupServiceState {
            case .finalizingPrimaryCard: return backupService.isPrimaryRing ? Localization.commonOriginRing : Localization.commonOriginCard
            case .finalizingBackupCard:
                return backupService.isFinalizingRing ? Localization.onboardingTitleBackupRing :
                    Localization.onboardingTitleBackupCard
            default: break
            }
        default: break
        }
        return super.title
    }

    // MARK: - Subtitle

    override var subtitle: String? {
        switch currentStep {
        case .selectBackupCards:
            switch backupCardsAddedCount {
            case 0: return Localization.onboardingSubtitleNoBackupCards
            case 1: return Localization.onboardingSubtitleOneBackupCard
            default: return Localization.onboardingSubtitleTwoBackupCards
            }
        case .backupIntro:
            return ""
        case .success:
            return Localization.onboardingSubtitleSuccessTangemWalletOnboarding
        case .backupCards:
            switch backupServiceState {
            case .finalizingPrimaryCard:
                if backupService.isFinalizingRing {
                    return Localization.onboardingSubtitleScanRing
                }

                guard let primaryCardId = backupService.primaryCard?.cardId,
                      let cardIdFormatted = CardIdFormatter(style: cardIdDisplayFormat).string(from: primaryCardId) else {
                    return super.subtitle
                }

                return Localization.onboardingSubtitleScanPrimaryCardFormat(cardIdFormatted)
            case .finalizingBackupCard(let index):
                if backupService.isFinalizingRing {
                    return Localization.onboardingSubtitleScanRing
                }

                let backupCardIds = backupService.backupCards.map { $0.cardId }
                let cardId = backupCardIds[index - 1]
                guard let cardIdFormatted = CardIdFormatter(style: cardIdDisplayFormat).string(from: cardId) else {
                    return super.subtitle
                }

                return Localization.onboardingSubtitleScanBackupCardFormat(cardIdFormatted)
            default: return super.subtitle
            }
        default: return super.subtitle
        }
    }

    // MARK: - Main Button setup

    override var mainButtonSettings: MainButton.Settings? {
        switch currentStep {
        case .createWallet, .pushNotifications, .seedPhraseIntro, .backupCards, .success, .scanPrimaryCard:
            return nil
        default:
            return MainButton.Settings(
                title: mainButtonTitle,
                icon: mainButtonIcon,
                style: mainButtonStyle,
                isLoading: isMainButtonBusy,
                isDisabled: !isMainButtonEnabled,
                action: mainButtonAction
            )
        }
    }

    override var mainButtonTitle: String {
        switch currentStep {
        case .selectBackupCards:
            return Localization.onboardingButtonAddBackupCard
        case .success:
            return input.isStandalone ? Localization.commonContinue : super.mainButtonTitle
        default: break
        }
        return super.mainButtonTitle
    }

    var mainButtonStyle: MainButton.Style {
        switch currentStep {
        case .selectBackupCards: return .secondary
        default: return .primary
        }
    }

    var isMainButtonEnabled: Bool {
        switch currentStep {
        case .selectBackupCards: return canAddBackupCards
        default: return true
        }
    }

    // MARK: - Supplement Button settings

    override var supplementButtonTitle: String {
        switch currentStep {
        case .backupCards:
            switch backupServiceState {
            case .finalizingPrimaryCard, .finalizingBackupCard:
                return backupService.isFinalizingRing ? Localization.onboardingButtonBackupRing : Localization.onboardingButtonBackupCard
            default: break
            }
        case .success:
            return input.isStandalone ? Localization.commonContinue : super.supplementButtonTitle
        default: break
        }

        return super.supplementButtonTitle
    }

    override var supplementButtonStyle: MainButton.Style {
        switch currentStep {
        case .createWallet, .selectBackupCards, .scanPrimaryCard, .backupCards, .success:
            return .primary
        default:
            return .secondary
        }
    }

    override var isSupplementButtonEnabled: Bool {
        switch currentStep {
        case .selectBackupCards: return backupCardsAddedCount > 0
        default: return true
        }
    }

    // MARK: -

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
        case .saveUserWallet, .pushNotifications, .seedPhraseIntro, .seedPhraseGeneration, .seedPhraseUserValidation, .seedPhraseImport, .addTokens:
            return true
        default: return false
        }
    }

    // MARK: - Other View related stuff

    override var isSupportButtonVisible: Bool {
        if case .success = currentStep {
            return false
        }

        return true
    }

    lazy var importSeedPhraseModel: OnboardingSeedPhraseImportViewModel? = .init(inputProcessor: SeedPhraseInputProcessor(), delegate: self)
    var generateSeedPhraseModel: OnboardingSeedPhraseGenerateViewModel?
    var validationUserSeedPhraseModel: OnboardingSeedPhraseUserValidationViewModel?

    var canShowThirdCardImage: Bool {
        return true
    }

    var canShowOriginCardLabel: Bool {
        return currentStep == .backupCards
    }

    // MARK: - Private properties

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
        return backupService.canAddBackupCards
    }

    private var backupServiceState: BackupService.State {
        return backupService.currentState
    }

    @Published private var previewBackupCardsAdded: Int = 0
    @Published private var previewBackupState: BackupService.State = .finalizingPrimaryCard

    private let backupService: BackupService
    private var cardInitializer: CardInitializer?
    private let pendingBackupManager = PendingBackupManager()

    // MARK: - Initializer

    override init(input: OnboardingInput, coordinator: OnboardingCoordinator) {
        backupService = input.backupService
        cardInitializer = input.cardInitializer

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

        bind()
    }

    func onAppear() {
        if isInitialAnimPlayed {
            return
        }

        playInitialAnim()
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
                case .success:
                    withAnimation {
                        self?.fireConfetti()
                    }
                default:
                    break
                }
            }
            .store(in: &bag)

        subscribeToScreenshots()
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
        if currentStep.isCreateWalletStep,
           let backupIntroStepIndex = steps.firstIndex(where: { $0.isInitialBackupStep }) {
            goToStep(with: backupIntroStepIndex)
            return
        }

        super.goToNextStep()
    }

    // MARK: - Main button action

    override func mainButtonAction() {
        switch currentStep {
        case .createWalletSelector:
            createWallet()
        case .seedPhraseGeneration:
            goToStep(.seedPhraseUserValidation)
        case .backupIntro:
            if NFCUtils.isPoorNfcQualityDevice {
                alert = AlertBuilder.makeOldDeviceAlert()
            } else {
                if let disabledLocalizedReason = input.cardInput.demoBackupDisabledLocalizedReason {
                    alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
                } else {
                    goToNextStep()
                }
            }
        case .selectBackupCards:
            addBackupCard()
        default:
            break
        }
    }

    // MARK: - Supplement button action

    override func supplementButtonAction() {
        switch currentStep {
        case .createWallet:
            createWallet()
        case .createWalletSelector:
            Analytics.log(.onboardingSeedButtonOtherCreateWalletOptions)
            goToStep(.seedPhraseIntro)
        case .seedPhraseIntro:
            Analytics.log(.onboardingSeedButtonImportWallet)
            importSeedPhraseModel?.resetModel()
            goToStep(.seedPhraseImport)
        case .backupIntro:
            Analytics.log(.backupSkipped)
            if steps.contains(.saveUserWallet) {
                goToStep(.saveUserWallet)
            } else if steps.contains(.addTokens) {
                goToStep(.addTokens)
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
        case .backupCards:
            backupCard()
        case .success:
            goToNextStep()
        case .scanPrimaryCard:
            readPrimaryCard()
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

    override func backButtonAction() {
        switch currentStep {
        case .seedPhraseIntro:
            goToStep(.createWalletSelector)
        case .seedPhraseGeneration:
            goToStep(.seedPhraseIntro)
        case .seedPhraseImport:
            UIApplication.shared.endEditing()
            goToStep(.seedPhraseIntro)
        case .seedPhraseUserValidation:
            goToStep(.seedPhraseGeneration)
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

    override func didAskToSaveUserWallets(agreed: Bool) {
        super.didAskToSaveUserWallets(agreed: agreed)
        trySaveAccessCodes()
    }

    private func back() {
        closeOnboarding()

        backupService.discardIncompletedBackup()
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

        createWalletOnPrimaryCard(using: nil, mnemonicPassphrase: nil, walletCreationType: .privateKey)
    }

    private func readPrimaryCard() {
        isMainButtonBusy = true

        stepPublisher = readPrimaryCardPublisher()
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .first()
            .mapToVoid()
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
                receiveValue: { [weak self] in
                    self?.processPrimaryCardScan()
                }
            )
    }

    private func createWalletOnPrimaryCard(using mnemonic: Mnemonic? = nil, mnemonicPassphrase passphrase: String?, walletCreationType: WalletCreationType) {
        guard let cardInitializer else { return }

        AppSettings.shared.cardsStartedActivation.insert(input.primaryCardId)

        cardInitializer.initializeCard(mnemonic: mnemonic, passphrase: passphrase) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let cardInfo):
                initializeUserWallet(from: cardInfo)

                if let userWalletModel, userWalletModel.hasImportedWallets {
                    let userWalletId = userWalletModel.userWalletId.stringValue
                    TangemFoundation.runTask(in: self) { model in
                        try? await model.tangemApiService.setWalletInitialized(userWalletId: userWalletId)
                    }
                }

                if let primaryCard = cardInfo.primaryCard {
                    backupService.setPrimaryCard(primaryCard)
                }

                Analytics.log(event: .walletCreatedSuccessfully, params: walletCreationType.params)
                processPrimaryCardScan()
            case .failure(let error):
                if !error.toTangemSdkError().isUserCancelled {
                    AppLog.shared.error(error, params: [.action: .preparePrimary])

                    if case TangemSdkError.walletAlreadyCreated = error {
                        alert = AlertBuilder.makeAlert(
                            title: Localization.onboardingActivationErrorTitle,
                            message: Localization.onboardingActivationErrorMessage,
                            primaryButton: .default(Text(Localization.warningButtonOk), action: { [weak self] in
                                self?.cardInitializer?.shouldReset = true
                            }),
                            secondaryButton: .default(Text(Localization.commonSupport), action: { [weak self] in
                                self?.openSupport()
                            })
                        )
                    } else {
                        alert = error.alertBinder
                    }
                }
            }

            isMainButtonBusy = false
        }
    }

    private func readPrimaryCardPublisher() -> AnyPublisher<Void, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else { return }

                backupService.readPrimaryCard(cardId: input.primaryCardId) { result in
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
                Future { [weak self] promise in
                    self?.backupService.addBackupCard { result in
                        switch result {
                        case .success(let card):
                            promise(.success(card))
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    }
                }
            }
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .first()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.processBackupError(error)
                    self?.isMainButtonBusy = false
                }
                self?.stepPublisher = nil
            }, receiveValue: { [weak self] card, _ in
                self?.loadImage(for: card)
                self?.updateStep()
                withAnimation {
                    self?.isMainButtonBusy = false
                }
            })
    }

    private func loadImage(for card: Card) {
        let input = OnboardingInput.ImageLoadInput(
            supportsOnlineImage: true,
            cardId: card.cardId,
            cardPublicKey: card.cardPublicKey
        )

        switch backupService.addedBackupCardsCount {
        case 1:
            loadSecondImage(imageLoadInput: input)
        case 2:
            loadThirdImage(imageLoadInput: input)
        default:
            break
        }
    }

    private func backupCard() {
        // Sometimes a step state does not update for an unknown reason.
        if backupServiceState == .finished {
            goToNextStep()
            return
        }

        isMainButtonBusy = true

        let ringUtil = RingUtil()

        // Ring onboarding. Set custom image for ring
        backupService.config.setupForProduct(backupService.isFinalizingRing ? .ring : .card)

        let containsRing = backupService.allBatchIds.contains(where: { ringUtil.isRing(batchId: $0) })

        stepPublisher =
            Deferred {
                Future { [weak self] promise in
                    guard let self else { return }

                    backupService.proceedBackup { [weak self] result in
                        guard let self else { return }

                        // Ring onboarding. Reset to defaults
                        backupService.config.setupForProduct(.any)

                        switch result {
                        case .success(let updatedCard):
                            userWalletModel?.addAssociatedCard(updatedCard.cardId)
                            pendingBackupManager.onProceedBackup(updatedCard)
                            if updatedCard.cardId == backupService.primaryCard?.cardId {
                                userWalletModel?.onBackupUpdate(type: .primaryCardBackuped(card: updatedCard))
                            }

                            if backupServiceState == .finished {
                                // Ring onboarding. Save userWalletId with ring, except interrupted backups
                                if containsRing,
                                   let userWalletId = userWalletModel?.userWalletId.stringValue {
                                    AppSettings.shared.userWalletIdsWithRing.insert(userWalletId)
                                }

                                trySaveAccessCodes()

                                pendingBackupManager.onBackupCompleted()
                                userWalletModel?.onBackupUpdate(type: .backupCompleted)
                                Analytics.log(
                                    event: .backupFinished,
                                    params: [.cardsCount: String((updatedCard.backupStatus?.backupCardsCount ?? 0) + 1)]
                                )
                            }

                            promise(.success(()))
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    }
                }
            }
            .combineLatest(NotificationCenter.didBecomeActivePublisher)
            .delay(for: 0.1, scheduler: DispatchQueue.main)
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    AppLog.shared.error(error, params: [.action: .proceedBackup])
                    let sdkError = error.toTangemSdkError()
                    if !sdkError.isUserCancelled {
                        self?.alert = sdkError.alertBinder
                    }

                    Analytics.tryLogCardVerificationError(error, source: .backup)
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

    private func trySaveAccessCodes() {
        guard AppSettings.shared.saveAccessCodes,
              let accessCode = accessCode,
              let cardIds = cardIds else {
            return
        }

        let accessCodeData: Data = accessCode.sha256()
        let accessCodeRepository = AccessCodeRepository()
        try? accessCodeRepository.save(accessCodeData, for: cardIds)
    }

    private func previewGoToNextStepDelayed(_ delay: TimeInterval = 2) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.goToNextStep()
            self.isMainButtonBusy = false
        }
    }

    private func processBackupError(_ error: Error) {
        AppLog.shared.error(error, params: [.action: .addbackup])

        if let tangemSdkError = error as? TangemSdkError,
           case .backupFailedNotEmptyWallets(let cardId) = tangemSdkError {
            requestResetCard(with: cardId)
            return
        }

        let sdkError = error.toTangemSdkError()
        if !sdkError.isUserCancelled {
            alert = sdkError.alertBinder
        }
    }

    private func requestResetCard(with cardId: String) {
        alert = AlertBuilder.makeAlert(
            title: Localization.commonAttention,
            message: Localization.onboardingLinkingErrorCardWithWallets,
            primaryButton: .destructive(Text(Localization.cardSettingsActionSheetReset), action: { [weak self] in
                self?.resetCard(with: cardId)
            }),
            secondaryButton: .default(Text(Localization.commonCancel)) {
                Analytics.log(.backupResetCardNotification, params: [.option: .cancel])
            }
        )
    }

    private func resetCard(with cardId: String) {
        Analytics.log(.backupResetCardNotification, params: [.option: .reset])
        isMainButtonBusy = true

        let interactor = FactorySettingsResettingCardInteractor(with: cardId)
        interactor.resetCard { [weak self] result in
            switch result {
            case .failure(let error):
                if error.isUserCancelled {
                    break
                }

                self?.alert = error.alertBinder
            case .success:
                break
            }

            self?.isMainButtonBusy = false
            withExtendedLifetime(interactor) {}
        }
    }

    private func loadSecondImage(imageLoadInput: OnboardingInput.ImageLoadInput) {
        loadImage(
            supportsOnlineImage: imageLoadInput.supportsOnlineImage,
            cardId: imageLoadInput.cardId,
            cardPublicKey: imageLoadInput.cardPublicKey
        )
        .sink { [weak self] image in
            withAnimation {
                self?.secondImage = image
            }
        }
        .store(in: &bag)
    }

    private func loadThirdImage(imageLoadInput: OnboardingInput.ImageLoadInput) {
        loadImage(
            supportsOnlineImage: imageLoadInput.supportsOnlineImage,
            cardId: imageLoadInput.cardId,
            cardPublicKey: imageLoadInput.cardPublicKey
        )
        .sink { [weak self] image in
            withAnimation {
                self?.thirdImage = image
            }
        }
        .store(in: &bag)
    }
}

// MARK: - Seed phrase related

extension WalletOnboardingViewModel {
    func openReadMoreAboutSeedPhraseScreen() {
        let websiteLanguageCode: String
        switch Locale.current.languageCode {
        case LanguageCode.ru, LanguageCode.by:
            websiteLanguageCode = LanguageCode.ru
        default:
            websiteLanguageCode = LanguageCode.en
        }
        let baseUrl = AppEnvironment.current.tangemComBaseUrl
        let url = baseUrl.appendingPathComponent("seed-phrase-\(websiteLanguageCode).html")
        coordinator?.openWebView(with: url)
        Analytics.log(.onboardingSeedButtonReadMore)
    }

    func generateSeedPhrase() {
        Analytics.log(.onboarindgSeedButtonGenerateSeedPhrase)
        do {
            try seedPhraseManager.generateSeedPhrase()
            generateSeedPhraseModel = .init(seedPhraseManager: seedPhraseManager, delegate: self)
            goToNextStep()
        } catch {
            alert = error.alertBinder
        }
    }

    private func subscribeToScreenshots() {
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .filter { [weak self] _ in
                guard let self else { return false }
                switch currentStep {
                case .seedPhraseGeneration, .seedPhraseUserValidation, .seedPhraseImport:
                    return true
                default:
                    return false
                }
            }
            .sink { [weak self] _ in
                self?.alert = AlertBuilder.makeOkGotItAlert(message: Localization.onboardingSeedScreenshotAlert)
                Analytics.log(.onboardingSeedScreenCapture)
            }
            .store(in: &bag)
    }
}

extension WalletOnboardingViewModel: OnboardingSeedPhraseGenerationDelegate {
    func continuePhraseGeneration(with entropyLength: EntropyLength) {
        guard let mnemonic = seedPhraseManager.mnemonics[entropyLength] else {
            alert = MnemonicError.mnenmonicCreationFailed.alertBinder
            return
        }

        let words = mnemonic.mnemonicComponents
        guard words.count == entropyLength.wordCount else {
            alert = MnemonicError.invalidWordCount.alertBinder
            return
        }

        validationUserSeedPhraseModel = OnboardingSeedPhraseUserValidationViewModel(validationInput: .init(
            secondWord: words[1],
            seventhWord: words[6],
            eleventhWord: words[10],
            createWalletAction: { [weak self, mnemonic] in
                self?.createWalletOnPrimaryCard(using: mnemonic, mnemonicPassphrase: nil, walletCreationType: .newSeed)
            }
        ))
        mainButtonAction()
    }
}

extension WalletOnboardingViewModel: SeedPhraseImportDelegate {
    func importSeedPhrase(mnemonic: Mnemonic, passphrase: String?) {
        let isWithPassphrase = !(passphrase ?? "").isEmpty
        createWalletOnPrimaryCard(
            using: mnemonic,
            mnemonicPassphrase: passphrase,
            walletCreationType: .seedImport(
                length: mnemonic.mnemonicComponents.count,
                isWithPassphrase: isWithPassphrase
            )
        )
    }
}

// MARK: - Wallet creation type

extension WalletOnboardingViewModel {
    enum WalletCreationType {
        case privateKey
        case newSeed
        case seedImport(length: Int, isWithPassphrase: Bool)

        var params: [Analytics.ParameterKey: String] {
            switch self {
            case .privateKey:
                return [.creationType: Analytics.ParameterValue.walletCreationTypePrivateKey.rawValue]
            case .newSeed:
                return [.creationType: Analytics.ParameterValue.walletCreationTypeNewSeed.rawValue]
            case .seedImport(let length, let isWithPassphrase):
                return [
                    .creationType: Analytics.ParameterValue.walletCreationTypeSeedImport.rawValue,
                    .seedLength: "\(length)",
                    .passphrase: isWithPassphrase ? Analytics.ParameterValue.full.rawValue : Analytics.ParameterValue.empty.rawValue,
                ]
            }
        }
    }
}

// MARK: - Navigation

extension WalletOnboardingViewModel {
    func openAccessCode() {
        coordinator?.openAccessCodeView(callback: saveAccessCode)
    }
}

extension NotificationCenter {
    static var didBecomeActivePublisher: AnyPublisher<Notification, Error> {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

private extension BackupService {
    var allCardIds: [String] {
        [primaryCard?.cardId].compactMap { $0 } + backupCards.map { $0.cardId }
    }

    // for ring onboarding
    var allBatchIds: [String] {
        [primaryCard?.batchId].compactMap { $0 } + backupCards.compactMap { $0.batchId }
    }

    var isFinalizingRing: Bool {
        if let finalizingBatchId,
           RingUtil().isRing(batchId: finalizingBatchId) {
            return true
        }

        return false
    }

    var isPrimaryRing: Bool {
        if let primaryCardBatchId = primaryCard?.batchId {
            return RingUtil().isRing(batchId: primaryCardBatchId)
        }

        return false
    }

    // for ring onboarding
    private var finalizingBatchId: String? {
        if currentState == .finalizingPrimaryCard,
           let batchId = primaryCard?.batchId {
            return batchId
        }

        if case .finalizingBackupCard(let index) = currentState,
           let batchId = backupCards[index - 1].batchId {
            return batchId
        }

        return nil
    }
}
