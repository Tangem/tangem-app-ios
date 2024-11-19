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

    lazy var accessCodeSetupViewModel = VisaOnboardingAccessCodeSetupViewModel(delegate: self)

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
        case .welcome, .pushNotifications, .saveUserWallet:
            alert = AlertBuilder.makeExitAlert(okAction: weakify(self, forFunction: VisaOnboardingViewModel.closeOnboarding))
        case .accessCode:
            guard accessCodeSetupViewModel.canGoBack() else {
                return
            }

            goToStep(.welcome)
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

private extension VisaOnboardingViewModel {
    func goToNextStep() {
        switch currentStep {
        case .welcome:
            goToStep(.accessCode)
        case .accessCode:
            break
        case .saveUserWallet, .pushNotifications:
            break
        case .success:
            closeOnboarding()
        }
    }

    func goToStep(_ step: VisaOnboardingStep) {
        guard steps.contains(step) else {
            AppLog.shared.debug("Failed to find step \(step)")
            return
        }

        withAnimation {
            currentStep = step
        }
    }

    func saveAccessCode(_ code: String) {}

    func closeOnboarding() {
        userWalletRepository.updateSelection()
        coordinator?.closeOnboarding()
    }

    // This function will be updated in IOS-8509. Requirements for activation flow was reworked,
    // so for now this function is for testing purposes
    func startActivation() {
        guard activationManagerTask == nil else {
            print("Activation task already exists, skipping")
            return
        }

        guard
            case .cardInfo(let cardInfo) = input.cardInput,
            case .visa(let accessToken, let refreshToken) = cardInfo.walletData
        else {
            print("Wrong onboarding input")
            return
        }

        let authorizationTokens = VisaAuthorizationTokens(accessToken: accessToken, refreshToken: refreshToken)
        activationManagerTask = runTask(in: self, isDetached: false) { viewModel in
            try await viewModel.visaActivationManager.startActivation(authorizationTokens)
        }.eraseToAnyCancellable()
    }
}

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

extension VisaOnboardingViewModel: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        goToNextStep()
    }
}

extension VisaOnboardingViewModel: VisaOnboardingAccessCodeSetupDelegate {
    /// We need to show alert in parent view, otherwise it won't be presented
    @MainActor
    func showAlert(_ alert: AlertBinder) async {
        self.alert = alert
    }

    func useSelectedCode(accessCode: String) async throws {
        try await Task.sleep(seconds: 5)
        throw "Will be implemented later IOS-8509"
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

        return .init(
            input: inputFactory.makeOnboardingInput()!,
            visaActivationManager: VisaActivationManagerFactory().make(
                urlSessionConfiguration: .default,
                logger: AppLog.shared
            ),
            coordinator: coordinator
        )
    }
}
#endif
