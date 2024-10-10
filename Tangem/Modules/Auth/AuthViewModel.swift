//
//  AuthViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSdk

final class AuthViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var showTroubleshootingView: Bool = false
    @Published var isScanningCard: Bool = false
    @Published var error: AlertBinder?

    var unlockWithBiometryButtonTitle: String {
        Localization.welcomeUnlock(BiometricAuthorizationUtils.biometryType.name)
    }

    // MARK: - Dependencies

    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private var unlockOnStart: Bool
    private weak var coordinator: AuthRoutable?

    init(
        unlockOnStart: Bool,
        coordinator: AuthRoutable
    ) {
        self.unlockOnStart = unlockOnStart
        self.coordinator = coordinator
    }

    func tryAgain() {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .signIn])
        unlockWithCard()
    }

    func openScanCardManual() {
        Analytics.log(.cantScanTheCardButtonBlog, params: [.source: .signIn])
        coordinator?.openScanCardManual()
    }

    func requestSupport() {
        Analytics.log(.requestSupport, params: [.source: .signIn])
        failedCardScanTracker.resetCounter()
        openMail()
    }

    func unlockWithBiometryButtonTapped() {
        Analytics.log(.buttonBiometricSignIn)
        unlockWithBiometry()
    }

    func unlockWithBiometry() {
        userWalletRepository.unlock(with: .biometry) { [weak self] result in
            guard let self else { return }

            didFinishUnlocking(result)

            switch result {
            case .success(let model), .partial(let model, _):
                let walletHasBackup = Analytics.ParameterValue.affirmativeOrNegative(for: model.hasBackupCards)
                Analytics.log(event: .signedIn, params: [
                    .signInType: Analytics.ParameterValue.signInTypeBiometrics.rawValue,
                    .walletsCount: "\(userWalletRepository.models.count)",
                    .walletHasBackup: walletHasBackup.rawValue,
                ])
            default:
                break
            }
        }
    }

    func unlockWithCard() {
        isScanningCard = true
        Analytics.beginLoggingCardScan(source: .auth)

        userWalletRepository.unlock(with: .card(userWalletId: nil, scanner: CardScannerFactory().makeDefaultScanner())) { [weak self] result in
            guard let self else { return }

            didFinishUnlocking(result)

            switch result {
            case .success(let model), .partial(let model, _):
                let walletHasBackup = Analytics.ParameterValue.affirmativeOrNegative(for: model.hasBackupCards)
                Analytics.log(event: .signedIn, params: [
                    .signInType: Analytics.ParameterValue.card.rawValue,
                    .walletsCount: "\(userWalletRepository.models.count)",
                    .walletHasBackup: walletHasBackup.rawValue,
                ])
            default:
                break
            }
        }
    }

    func onAppear() {
        Analytics.log(.signInScreenOpened)
        incomingActionManager.becomeFirstResponder(self)
    }

    func onDidAppear() {
        guard unlockOnStart else { return }

        unlockOnStart = false

        DispatchQueue.main.async {
            self.unlockWithBiometry()
        }
    }

    func onDisappear() {
        incomingActionManager.resignFirstResponder(self)
    }

    private func didFinishUnlocking(_ result: UserWalletRepositoryResult?) {
        isScanningCard = false

        if result?.isSuccess != true {
            incomingActionManager.discardIncomingAction()
        }

        guard let result else { return }

        switch result {
        case .troubleshooting:
            Analytics.log(.cantScanTheCard, params: [.source: .signIn])
            showTroubleshootingView = true
        case .onboarding(let input):
            openOnboarding(with: input)
        case .error(let error):
            if case .userCancelled = error as? TangemSdkError {
                break
            } else {
                self.error = error.alertBinder
            }
        case .success(let model), .partial(let model, _):
            openMain(with: model)
        }
    }
}

// MARK: - Navigation

extension AuthViewModel {
    func openMail() {
        coordinator?.openMail(with: failedCardScanTracker, recipient: EmailConfig.default.recipient)
    }

    func openOnboarding(with input: OnboardingInput) {
        coordinator?.openOnboarding(with: input)
    }

    func openMain(with model: UserWalletModel) {
        coordinator?.openMain(with: model)
    }
}

// MARK: - IncomingActionResponder

extension AuthViewModel: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        if !unlockOnStart {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.unlockWithBiometry()
            }
        }

        switch action {
        case .start:
            return true
        default:
            return false
        }
    }
}
