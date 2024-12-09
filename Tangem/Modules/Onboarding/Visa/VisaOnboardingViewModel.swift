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
    lazy var welcomeViewModel: VisaOnboardingWelcomeViewModel = .init(
        activationState: .newActivation,
        userName: "World",
        imagePublisher: nil,
        startActivationDelegate: weakify(self, forFunction: VisaOnboardingViewModel.goToNextStep)
    )

    lazy var accessCodeSetupViewModel = VisaOnboardingAccessCodeSetupViewModel(accessCodeValidator: visaActivationManager, delegate: self)
    lazy var walletSelectorViewModel = VisaOnboardingActivationWalletSelectorViewModel(delegate: self)
    var tangemWalletApproveViewModel: VisaOnboardingTangemWalletConfirmationViewModel?

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
        }
    }

    func backButtonAction() {
        switch currentStep {
        case .welcome, .pushNotifications, .saveUserWallet, .selectWalletForApprove:
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
}

// MARK: - Steps navigation logic

private extension VisaOnboardingViewModel {
    func goToNextStep() {
        switch currentStep {
        case .welcome:
            goToStep(.accessCode)
        case .accessCode:
            goToStep(.selectWalletForApprove)
        case .selectWalletForApprove, .approveUsingTangemWallet, .saveUserWallet, .pushNotifications:
            break
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
}

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
            goToNextStep()
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

extension VisaOnboardingViewModel: VisaOnboardingWalletSelectorDelegate {
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
        throw "Backend not ready... Even requirements"
    }
}

extension VisaOnboardingViewModel: VisaOnboardingTangemWalletApproveDataProvider {
    func loadDataToSign() async throws -> Data {
//        throw "Backend not ready... Even requirements"
        Data(hex: "01231543809154315741395431578392174938")
    }
}

// MARK: - Close onboarding funcs

private extension VisaOnboardingViewModel {
    func showCloseOnboardingAlert() {
        alert = AlertBuilder.makeExitAlert(okAction: weakify(self, forFunction: VisaOnboardingViewModel.closeOnboarding))
    }

    func closeOnboarding() {
        userWalletRepository.updateSelection()
        coordinator?.closeOnboarding()
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
        let cardMockConfig = VisaConfig(card: cardMock.cardInfo.card)
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
                cardInput: .init(
                    cardId: cardMock.card.cardId,
                    cardPublicKey: cardMock.card.cardPublicKey
                ),
                tangemSdk: TangemSdkDefaultFactory().makeTangemSdk(),
                urlSessionConfiguration: .default,
                logger: AppLog.shared
            ),
            coordinator: coordinator
        )
    }
}
#endif
