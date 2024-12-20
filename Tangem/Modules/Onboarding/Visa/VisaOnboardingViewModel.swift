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
}

protocol VisaOnboardingRoutable: AnyObject {
    func closeOnboarding()
    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType)
}

class VisaOnboardingViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

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
        activationStatus: visaActivationManager.activationStatus,
        isAccessCodeSet: visaActivationManager.isAccessCodeSet,
        cardImage: $cardImage,
        delegate: self
    )

    lazy var accessCodeSetupViewModel = VisaOnboardingAccessCodeSetupViewModel(accessCodeValidator: visaActivationManager, delegate: self)
    lazy var walletSelectorViewModel = VisaOnboardingApproveWalletSelectorViewModel(delegate: self)
    var tangemWalletApproveViewModel: VisaOnboardingTangemWalletDeployApproveViewModel?
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
        return true
    }

    var isBackButtonEnabled: Bool {
        return true
    }

    var isSupportButtonVisible: Bool {
        return true
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

        loadImage(input.cardInput.imageLoadInput)
    }

    func backButtonAction() {
        switch currentStep {
        case .welcome, .welcomeBack, .pushNotifications, .inProgress, .pinSelection, .saveUserWallet, .selectWalletForApprove:
            showCloseOnboardingAlert()
        case .accessCode:
            guard accessCodeSetupViewModel.goBack() else {
                return
            }

            goToStep(.welcome)
        case .approveUsingTangemWallet:
            goToStep(.selectWalletForApprove)
        case .success:
            break
        }
    }

    func openSupport() {
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

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[VisaOnboardingViewModel] - \(message())")
    }
}

// MARK: - Steps navigation logic

private extension VisaOnboardingViewModel {
    func goToNextStep() {
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
        case .selectWalletForApprove, .approveUsingTangemWallet, .saveUserWallet, .pushNotifications:
            break
        case .inProgress:
            /// Should be decided in `proceedFromInProgress`
            break
        case .pinSelection:
            goToStep(.inProgress)
        case .success:
            closeOnboarding()
        }
    }

    func goToStep(_ step: VisaOnboardingStep) {
        guard let stepIndex = steps.firstIndex(of: step) else {
            AppLog.shared.debug("Failed to find step \(step)")
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
}

// MARK: - In progress logic&navigation

extension VisaOnboardingViewModel: VisaOnboardingInProgressDelegate {
    func canProceedOnboarding() async throws -> Bool {
        let currentState = visaActivationManager.activationRemoteState
        let newLoadedState = try await visaActivationManager.refreshActivationRemoteState()

        return currentState != newLoadedState
    }

    @MainActor
    func proceedFromInProgress() async {
        switch visaActivationManager.activationRemoteState {
        case .activated:
            goToStep(.saveUserWallet)
        case .blockedForActivation:
            // TODO: Discuss with analyst
            await showAlert("This card was blocked... Is this even possible?..".alertBinder)
        case .paymentAccountDeploying:
            inProgressViewModel = VisaOnboardingViewModelsBuilder().buildInProgressModel(
                activationRemoteState: .paymentAccountDeploying,
                delegate: self
            )
            goToStep(.inProgress)
        case .waitingForActivationFinishing:
            inProgressViewModel = VisaOnboardingViewModelsBuilder().buildInProgressModel(
                activationRemoteState: .waitingForActivationFinishing,
                delegate: self
            )
            goToStep(.inProgress)
        case .cardWalletSignatureRequired, .customerWalletSignatureRequired:
            await showAlert("Invalid card activation state. Please contact support".alertBinder)
        case .waitingPinCode:
            goToStep(.pinSelection)
        }
    }
}

// MARK: - Biometry delegate

extension VisaOnboardingViewModel: UserWalletStorageAgreementRoutable {
    func didAgreeToSaveUserWallets() {
        BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason) { [weak self] result in
            let biometryAccessGranted: Bool
            switch result {
            case .failure(let error):
                if error.isUserCancelled {
                    return
                }

                AppLog.shared.error(error)

                biometryAccessGranted = false
//                self?.didAskToSaveUserWallets(agreed: false)
            case .success:
                biometryAccessGranted = true
//                self?.didAskToSaveUserWallets(agreed: true)
            }

            Analytics.log(.allowBiometricID, params: [
                .state: Analytics.ParameterValue.toggleState(for: biometryAccessGranted),
            ])

            self?.goToNextStep()
        }
    }

    func didDeclineToSaveUserWallets() {
//        didAskToSaveUserWallets(agreed: false)
        goToNextStep()
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

    func useSelectedCode(accessCode: String) async throws {
        try visaActivationManager.saveAccessCode(accessCode: accessCode)
        try await visaActivationManager.startActivation()
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
        try await visaActivationManager.startActivation()
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

// MARK: - ApproveWalletSelectorDelegate

extension VisaOnboardingViewModel: VisaOnboardingApproveWalletSelectorDelegate {
    func useExternalWallet() {
        // TODO: IOS-8574
        alert = "TODO: IOS-8574".alertBinder
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
        /// Backend not ready... Even requirements. So right now we will return to Welcome Page
        goToStep(.welcome)
    }
}

extension VisaOnboardingViewModel: VisaOnboardingTangemWalletApproveDataProvider {
    func loadDataToSign() async throws -> Data {
        /// Backend not ready... Even requirements. So for now just generate random bytes with proper length for sign
        /// Later all data will be requested from `VisaActivationManager`
        let array = (0 ..< 32).map { _ -> UInt8 in
            UInt8(arc4random_uniform(255))
        }
        return Data(array)
    }
}

extension VisaOnboardingViewModel: OnboardingPinSelectionDelegate {
    func useSelectedPin(pinCode: String) async throws {
        try await visaActivationManager.setPINCode(pinCode)
        await proceedFromInProgress()
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

        var localizedDescription: String {
            switch self {
            case .missingTargetApproveAddress:
                return "Failed to find approve address. Please contact support"
            }
        }
    }
}

#if DEBUG
extension VisaOnboardingViewModel {
    static let coordinator = OnboardingCoordinator()

    static var mock: VisaOnboardingViewModel {
        let cardMock = CardMock.visa
        let visaUserWalletModelMock = CommonUserWalletModel.visaMock
        let activationStatus = VisaCardActivationStatus.notStartedActivation(activationInput: .init(
            cardId: cardMock.card.cardId,
            cardPublicKey: cardMock.card.cardPublicKey,
            isAccessCodeSet: cardMock.cardInfo.card.isAccessCodeSet
        ))
        let cardMockConfig = VisaConfig(card: cardMock.cardInfo.card, activationStatus: activationStatus)
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
            visaActivationManager: VisaActivationManagerFactory().make(
                initialActivationStatus: activationStatus,
                tangemSdk: TangemSdkDefaultFactory().makeTangemSdk(),
                urlSessionConfiguration: .default,
                logger: AppLog.shared
            ),
            coordinator: coordinator
        )
    }
}
#endif
