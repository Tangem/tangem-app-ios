//
//  VisaOnboardingViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 28.10.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk
import TangemFoundation
import TangemVisa

protocol VisaOnboardingAlertPresenter: AnyObject {
    @MainActor
    func showAlert(_ alert: AlertBinder) async
    @MainActor
    func showContactSupportAlert(for error: Error) async
}

protocol VisaOnboardingRoutable: OnboardingRoutable, OnboardingBrowserRoutable {}

class VisaOnboardingViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    @Published var shouldFireConfetti = false
    @Published var currentProgress: CGFloat = 0
    @Published var steps: [VisaOnboardingStep] = []
    @Published var currentStep: VisaOnboardingStep = .welcome
    @Published var alert: AlertBinder?
    @Published var cardImage: Image?

    var navigationBarHeight: CGFloat { OnboardingLayoutConstants.navbarSize.height }
    var progressBarHeight: CGFloat { OnboardingLayoutConstants.progressBarHeight }
    var progressBarPadding: CGFloat { OnboardingLayoutConstants.progressBarPadding }

    // MARK: - Subview ViewModels

    lazy var userWalletStorageAgreementViewModel = UserWalletStorageAgreementViewModel(coordinator: self)
    lazy var pushNotificationsViewModel: PushNotificationsPermissionRequestViewModel? = {
        guard let permissionManager = input.pushNotificationsPermissionManager else {
            return nil
        }
        return PushNotificationsPermissionRequestViewModel(permissionManager: permissionManager, delegate: self)
    }()

    // TODO: - Will be change later after clarification about authorization flow
    lazy var welcomeViewModel: VisaOnboardingWelcomeViewModel = VisaOnboardingViewModelsBuilder().buildWelcomeModel(
        activationStatus: visaActivationManager.activationLocalState,
        isAccessCodeSet: visaActivationManager.isAccessCodeSet,
        cardImage: $cardImage,
        delegate: self
    )

    lazy var accessCodeSetupViewModel = VisaOnboardingAccessCodeSetupViewModel(accessCodeValidator: visaActivationManager, delegate: self)
    lazy var walletSelectorViewModel = VisaOnboardingApproveWalletSelectorViewModel(remoteStateProvider: self, delegate: self)
    var tangemWalletApproveViewModel: VisaOnboardingTangemWalletDeployApproveViewModel?
    var walletConnectViewModel: VisaOnboardingWalletConnectViewModel?
    lazy var inProgressViewModel: VisaOnboardingInProgressViewModel? = VisaOnboardingViewModelsBuilder().buildInProgressModel(
        activationRemoteState: visaActivationManager.activationRemoteState,
        delegate: self
    )
    lazy var pinSelectionViewModel: OnboardingPinViewModel = .init(delegate: self)

    // MARK: - Computed properties

    var navigationBarTitle: String {
        currentStep.navigationTitle
    }

    var isBackButtonVisible: Bool {
        if currentStep == .success {
            return false
        }

        return true
    }

    var isBackButtonEnabled: Bool {
        return true
    }

    var isSupportButtonVisible: Bool {
        if currentStep == .success {
            return false
        }

        return true
    }

    private var isOnboardingFinished: Bool {
        currentStep == steps.last
    }

    private let input: OnboardingInput

    private let visaActivationManager: VisaActivationManager
    private var userWalletModel: UserWalletModel?
    private weak var coordinator: VisaOnboardingRoutable?

    private var activationManagerTask: AnyCancellable?

    init(
        input: OnboardingInput,
        visaActivationManager: VisaActivationManager,
        coordinator: VisaOnboardingRoutable
    ) {
        self.input = input
        self.visaActivationManager = visaActivationManager
        self.coordinator = coordinator

        if case .visa(let visaSteps) = input.steps {
            steps = visaSteps
            currentStep = visaSteps.first ?? .welcome
        }

        if case .userWalletModel(let userWalletModel) = input.cardInput {
            self.userWalletModel = userWalletModel
        }

        loadImage(input.cardInput.imageLoadInput)
    }

    func backButtonAction() {
        switch currentStep {
        case .welcome, .welcomeBack, .pushNotifications, .paymentAccountDeployInProgress, .issuerProcessingInProgress, .pinSelection, .saveUserWallet, .selectWalletForApprove:
            showCloseOnboardingAlert()
        case .accessCode:
            guard accessCodeSetupViewModel.goBack() else {
                return
            }

            goToStep(.welcome)
        case .approveUsingTangemWallet:
            goToStep(.selectWalletForApprove)
        case .approveUsingWalletConnect:
            walletConnectViewModel?.cancelStatusUpdates()
            goToStep(.selectWalletForApprove)
        case .success:
            break
        }
    }

    func openSupport() {
        guard FeatureStorage.instance.isVisaAPIMocksEnabled else {
            openSupportSheet()
            return
        }

        VisaMocksManager.instance.showMocksMenu(
            openSupportAction: weakify(self, forFunction: VisaOnboardingViewModel.openSupportSheet),
            presenter: self
        )
    }

    func finishOnboarding() {
        handleOnboardingFinish()
    }

    private func openSupportSheet() {
        Analytics.log(.requestSupport, params: [.source: .onboarding])

        UIApplication.shared.endEditing()

        let dataCollector = DetailsFeedbackDataCollector(
            data: [
                .init(
                    userWalletEmailData: input.cardInput.emailData,
                    walletModels: userWalletModel?.walletModelsManager.walletModels ?? []
                ),
            ]
        )

        // TODO: Replace with Visa email config
        let emailConfig = input.cardInput.config?.emailConfig ?? .default

        coordinator?.openMail(
            with: dataCollector,
            recipient: emailConfig.recipient,
            emailType: .appFeedback(subject: emailConfig.subject)
        )
    }

    private func updateUserWalletModel(with card: CardDTO) {
        let activationStatus = visaActivationManager.activationLocalState
        let cardInfo = CardInfo(
            card: card,
            walletData: .visa(activationStatus),
            name: "Visa"
        )
        let userWalletModel = CommonUserWalletModelFactory().makeModel(cardInfo: cardInfo)
        self.userWalletModel = userWalletModel
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        VisaLogger.info(self, message())
    }
}

extension VisaOnboardingViewModel: CustomStringConvertible {
    var description: String { "VisaOnboardingViewModel" }
}

// MARK: - Steps navigation logic

private extension VisaOnboardingViewModel {
    func goToNextStep() {
        if isOnboardingFinished {
            handleOnboardingFinish()
            return
        }

        switch currentStep {
        case .welcome:
            goToStep(.accessCode)
        case .welcomeBack(let isAccessCodeSet):
            if isAccessCodeSet {
                /// Should be decided in `proceedToApproveWalletSelection()`
                break
            } else {
                goToStep(.accessCode)
            }
        case .accessCode:
            goToStep(.selectWalletForApprove)
        case .selectWalletForApprove, .approveUsingTangemWallet, .approveUsingWalletConnect:
            break
        case .issuerProcessingInProgress, .saveUserWallet, .pushNotifications:
            guard
                let index = steps.firstIndex(of: currentStep),
                index + 1 < steps.count
            else {
                return
            }

            goToStep(steps[index + 1])
        case .paymentAccountDeployInProgress:
            goToStep(.pinSelection)
        case .pinSelection:
            goToStep(.issuerProcessingInProgress)
        case .success:
            closeOnboarding()
        }
    }

    func goToStep(_ step: VisaOnboardingStep) {
        guard let stepIndex = steps.firstIndex(of: step) else {
            AppLogger.error(self, error: "Failed to find step \(step)")
            return
        }

        let step = steps[stepIndex]

        DispatchQueue.main.async {
            withAnimation {
                self.currentStep = step
                self.currentProgress = CGFloat(stepIndex + 1) / CGFloat(self.steps.count)
            }
        }
    }

    func handleOnboardingFinish() {
        guard let userWalletModel else {
            return
        }

        userWalletRepository.add(userWalletModel)
        coordinator?.onboardingDidFinish(userWalletModel: userWalletModel)
    }
}

// MARK: - In progress logic&navigation

extension VisaOnboardingViewModel: VisaOnboardingInProgressDelegate {
    func canProceedOnboarding() async throws -> Bool {
        let currentState = visaActivationManager.activationRemoteState
        let newLoadedState = try await visaActivationManager.refreshActivationRemoteState()

        return currentState != newLoadedState
    }

    @MainActor
    func proceedFromCurrentRemoteState() async {
        switch visaActivationManager.activationRemoteState {
        case .activated:
            visaActivationManager.setupRefreshTokenSaver(visaRefreshTokenRepository)

            goToNextStep()
        case .blockedForActivation:
            // TODO: Discuss with analyst
            await showAlert("This card was blocked... Is this even possible?..".alertBinder)
        case .paymentAccountDeploying:
            inProgressViewModel = VisaOnboardingViewModelsBuilder().buildInProgressModel(
                activationRemoteState: .paymentAccountDeploying,
                delegate: self
            )
            goToStep(.paymentAccountDeployInProgress)
        case .waitingForActivationFinishing:
            inProgressViewModel = VisaOnboardingViewModelsBuilder().buildInProgressModel(
                activationRemoteState: .waitingForActivationFinishing,
                delegate: self
            )
            goToStep(.issuerProcessingInProgress)
        case .cardWalletSignatureRequired, .customerWalletSignatureRequired:
            // TODO: IOS-9087
            await showAlert("Invalid card activation state. Please contact support".alertBinder)
        case .waitingPinCode:
            goToStep(.pinSelection)
        }
    }

    func openBrowser(at url: URL, onSuccess: @escaping (URL) -> Void) {
        coordinator?.openBrowser(at: url, onSuccess: onSuccess)
    }
}

// MARK: - Biometry delegate

extension VisaOnboardingViewModel: UserWalletStorageAgreementRoutable {
    func didAgreeToSaveUserWallets() {
        OnboardingUtils().requestBiometrics { [weak self] agreed in
            self?.didAskToSaveUserWallets(agreed: agreed)
            self?.goToNextStep()
        }
    }

    func didDeclineToSaveUserWallets() {
        didAskToSaveUserWallets(agreed: false)
        goToNextStep()
    }

    func didAskToSaveUserWallets(agreed: Bool) {
        visaActivationManager.setupRefreshTokenSaver(visaRefreshTokenRepository)
        OnboardingUtils().processSaveUserWalletRequestResult(agreed: agreed)
        trySaveAccessCode()
    }

    private func trySaveAccessCode() {
        guard let cardId = userWalletModel?.tangemApiAuthData.cardId else {
            return
        }

        let accessCode = accessCodeSetupViewModel.accessCode
        AccessCodeSaveUtility().trySave(accessCode: accessCode, cardIds: [cardId])
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension VisaOnboardingViewModel: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        goToNextStep()
    }
}

// MARK: - AccessCodeSetupDelegate

extension VisaOnboardingViewModel: VisaOnboardingAccessCodeSetupDelegate {
    /// We need to show alert in parent view, otherwise it won't be presented
    @MainActor
    func showAlert(_ alert: AlertBinder) async {
        self.alert = alert
    }

    @MainActor
    func showContactSupportAlert(for error: Error) async {
        let alert = AlertBuilder.makeAlert(
            title: Localization.commonError,
            message: "Failed to during activation process. Error: \(error.localizedDescription)",
            primaryButton: .default(
                Text(Localization.detailsRowTitleContactToSupport),
                action: { [weak self] in
                    self?.openSupport()
                }
            ),
            secondaryButton: .destructive(
                Text("Cancel Activation"),
                action: { [weak self] in
                    self?.closeOnboarding()
                }
            )
        )

        await showAlert(alert)
    }

    func useSelectedCode(accessCode: String) async throws {
        try visaActivationManager.saveAccessCode(accessCode: accessCode)
        let activationResponse = try await visaActivationManager.startActivation()
        updateUserWalletModel(with: .init(card: activationResponse.signedActivationOrder.cardSignedOrder))
        await proceedToApproveWalletSelection()
    }

    func closeOnboarding() {
        userWalletRepository.updateSelection()
        coordinator?.closeOnboarding()
    }
}

// MARK: - Welcome Delegate

extension VisaOnboardingViewModel: VisaOnboardingWelcomeDelegate {
    func openAccessCodeScreen() {
        goToNextStep()
    }

    func continueActivation() async throws {
        let activationResponse = try await visaActivationManager.startActivation()
        updateUserWalletModel(with: .init(card: activationResponse.signedActivationOrder.cardSignedOrder))
        await proceedToApproveWalletSelection()
    }
}

// MARK: - Approve pair search

private extension VisaOnboardingViewModel {
    func proceedToApproveWalletSelection() async {
        guard let targetAddress = visaActivationManager.targetApproveAddress else {
            await showAlert(OnboardingError.missingTargetApproveAddress.alertBinder)
            return
        }

        guard visaActivationManager.activationRemoteState == .customerWalletSignatureRequired else {
            await showAlert(OnboardingError.missingTargetApproveAddress.alertBinder)
            return
        }

        let searchUtility = VisaApprovePairSearchUtility(isTestnet: false)

        guard
            let approvePair = searchUtility.findApprovePair(
                for: targetAddress,
                userWalletModels: userWalletRepository.models
            )
        else {
            goToStep(.selectWalletForApprove)
            return
        }

        tangemWalletApproveViewModel = .init(
            targetWalletAddress: targetAddress,
            delegate: self,
            dataProvider: self,
            approvePair: approvePair
        )
        goToStep(.approveUsingTangemWallet)
    }
}

// MARK: - ApproveWalletSelector protocols

extension VisaOnboardingViewModel: VisaOnboardingRemoteStateProvider {
    func loadCurrentRemoteState() async throws -> VisaCardActivationRemoteState {
        try await visaActivationManager.refreshActivationRemoteState()
    }
}

extension VisaOnboardingViewModel: VisaOnboardingApproveWalletSelectorDelegate {
    func useExternalWallet() {
        walletConnectViewModel = .init(delegate: self)
        goToStep(.approveUsingWalletConnect)
    }

    func useTangemWallet() {
        // Default value will be removed and guard check will be added, when backend finished implementation
        let targetApproveAddress = visaActivationManager.targetApproveAddress ?? ""
        tangemWalletApproveViewModel = .init(
            targetWalletAddress: targetApproveAddress,
            delegate: self,
            dataProvider: self
        )
        goToStep(.approveUsingTangemWallet)
    }
}

extension VisaOnboardingViewModel: VisaOnboardingTangemWalletApproveDelegate {
    func processSignedData(_ signedData: Data) async throws {
        try await visaActivationManager.sendSignedCustomerWalletApprove(signedData)
        await proceedFromCurrentRemoteState()
    }
}

extension VisaOnboardingViewModel: VisaOnboardingTangemWalletApproveDataProvider {
    func loadDataToSign() async throws -> Data {
        return try await visaActivationManager.getCustomerWalletApproveHash()
    }
}

// MARK: - PinSelectionDelegate

extension VisaOnboardingViewModel: OnboardingPinSelectionDelegate {
    func useSelectedPin(pinCode: String) async throws {
        try await visaActivationManager.setPINCode(pinCode)
        await proceedFromCurrentRemoteState()
    }
}

// MARK: - Close onboarding funcs

private extension VisaOnboardingViewModel {
    func showCloseOnboardingAlert() {
        alert = AlertBuilder.makeExitAlert(okAction: weakify(self, forFunction: VisaOnboardingViewModel.closeOnboarding))
    }
}

// MARK: - Image loading

private extension VisaOnboardingViewModel {
    func loadImage(_ imageLoadInput: OnboardingInput.ImageLoadInput) {
        runTask(in: self, isDetached: false) { viewModel in
            do {
                let image = try await CardImageProvider(supportsOnlineImage: imageLoadInput.supportsOnlineImage)
                    .loadImage(cardId: imageLoadInput.cardId, cardPublicKey: imageLoadInput.cardPublicKey)
                    .map { $0.image }
                    .async()
                await runOnMain {
                    viewModel.cardImage = image
                }
            } catch {
                viewModel.log("Failed to load card image. Error: \(error)")
            }
        }
    }
}

private extension VisaOnboardingViewModel {
    enum OnboardingError: String, LocalizedError {
        case missingTargetApproveAddress
        case wrongRemoteState

        var localizedDescription: String {
            switch self {
            case .missingTargetApproveAddress:
                return "Failed to find approve address. Please contact support"
            case .wrongRemoteState:
                return "Wrong activation state. Please contact support"
            }
        }
    }
}

// MARK: Development menu

// TODO: IOS-8843 Remove along side with Feature toggle

extension VisaOnboardingViewModel: VisaMockMenuPresenter {
    func modalFromTop(_ vc: UIViewController) {
        UIApplication.modalFromTop(vc)
    }
}

#if DEBUG
extension VisaOnboardingViewModel {
    static let coordinator = OnboardingCoordinator()

    static var mock: VisaOnboardingViewModel {
        let cardMock = CardMock.visa
        let visaUserWalletModelMock = CommonUserWalletModel.visaMock
        let activationStatus = VisaCardActivationLocalState.notStartedActivation(activationInput: .init(
            cardId: cardMock.card.cardId,
            cardPublicKey: cardMock.card.cardPublicKey,
            isAccessCodeSet: cardMock.cardInfo.card.isAccessCodeSet
        ))
        let cardMockConfig = VisaConfig(card: cardMock.cardInfo.card, activationLocalState: activationStatus)
        let inputFactory = OnboardingInputFactory(
            cardInfo: cardMock.cardInfo,
            userWalletModel: visaUserWalletModelMock,
            sdkFactory: cardMockConfig,
            onboardingStepsBuilderFactory: cardMockConfig,
            pushNotificationsInteractor: PushNotificationsInteractorMock()
        )
        guard let cardInput = inputFactory.makeOnboardingInput() else {
            fatalError("Failed to generate card input for visa onboarding")
        }

        return .init(
            input: cardInput,
            visaActivationManager: VisaActivationManagerFactory(isMockedAPIEnabled: true).make(
                cardId: cardInput.primaryCardId,
                initialActivationStatus: activationStatus,
                tangemSdk: TangemSdkDefaultFactory().makeTangemSdk(),
                urlSessionConfiguration: .default
            ),
            coordinator: coordinator
        )
    }
}
#endif
