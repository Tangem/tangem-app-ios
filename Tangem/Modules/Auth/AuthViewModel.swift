//
//  AuthViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
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

    private weak var coordinator: AuthRoutable?

    private var unlockOnAppear: Bool

    init(unlockOnAppear: Bool = false, coordinator: AuthRoutable) {
        self.unlockOnAppear = unlockOnAppear
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
            self?.didFinishUnlocking(result)
        }
    }

    func unlockWithCard() {
        isScanningCard = true
        Analytics.beginLoggingCardScan(source: .auth)

        userWalletRepository.unlock(with: .card(userWalletId: nil, scanner: CardScannerFactory().makeDefaultScanner())) { [weak self] result in
            self?.didFinishUnlocking(result)
        }
    }

    func onAppear() {
        Analytics.log(.signInScreenOpened)
        incomingActionManager.becomeFirstResponder(self)

        if unlockOnAppear {
            DispatchQueue.main.async {
                self.unlockOnAppear = false
                self.unlockWithBiometry()
            }
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
            if error.isCancellationError {
                return
            }

            Analytics.tryLogCardVerificationError(error, source: .signIn)
            self.error = error.alertBinder
        case .success(let model), .partial(let model, _):
            openMain(with: model)
        }
    }
}

// MARK: - Navigation

extension AuthViewModel {
    func openMail() {
        coordinator?.openMail(with: BaseDataCollector(), recipient: EmailConfig.default.recipient)
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
        if !unlockOnAppear {
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
