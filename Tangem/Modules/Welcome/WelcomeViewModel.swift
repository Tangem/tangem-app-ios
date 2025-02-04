//
//  WelcomeViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 30.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSdk

class WelcomeViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    @Published var showTroubleshootingView: Bool = false
    @Published var error: AlertBinder?

    let storiesModel: StoriesViewModel

    var isScanningCard: CurrentValueSubject<Bool, Never> = .init(false)

    private var shouldScanOnAppear: Bool = false

    private weak var coordinator: WelcomeRoutable?

    init(coordinator: WelcomeRoutable, storiesModel: StoriesViewModel) {
        self.coordinator = coordinator
        self.storiesModel = storiesModel
    }

    deinit {
        AppLog.shared.debug("WelcomeViewModel deinit")
    }

    func scanCardTapped() {
        scanCard()
    }

    func tryAgain() {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .introduction])
        scanCard()
    }

    func openScanCardManual() {
        Analytics.log(.cantScanTheCardButtonBlog, params: [.source: .introduction])
        coordinator?.openScanCardManual()
    }

    func requestSupport() {
        Analytics.log(.requestSupport, params: [.source: .introduction])
        failedCardScanTracker.resetCounter()
        openMail()
    }

    func orderCard() {
        // For some reason the button can be tapped even after we've this flag to FALSE to disable it
        guard !isScanningCard.value else { return }

        openShop()
        Analytics.log(.buttonBuyCards)
    }

    func onAppear() {
        Analytics.log(.introductionProcessOpened)
        incomingActionManager.becomeFirstResponder(self)
    }

    func onDisappear() {
        incomingActionManager.resignFirstResponder(self)
    }

    internal func scanCard() {
        isScanningCard.send(true)
        Analytics.beginLoggingCardScan(source: .welcome)

        userWalletRepository.unlock(with: .card(userWalletId: nil, scanner: CardScannerFactory().makeDefaultScanner())) { [weak self] result in
            self?.isScanningCard.send(false)

            if result?.isSuccess != true {
                self?.incomingActionManager.discardIncomingAction()
            }

            guard
                let self, let result
            else {
                return
            }

            switch result {
            case .troubleshooting:
                Analytics.log(.cantScanTheCard, params: [.source: .introduction])
                showTroubleshootingView = true
            case .onboarding(let input):
                openOnboarding(with: input)
            case .error(let error):
                if error.isCancellationError {
                    return
                }

                Analytics.tryLogCardVerificationError(error, source: .signIn)
                self.error = error.alertBinder
            case .success(let model), .partial(let model, _): // partial unlock is impossible in this case
                openMain(with: model)
            }
        }
    }
}

// MARK: - Navigation

extension WelcomeViewModel {
    func openOnboarding(with input: OnboardingInput) {
        coordinator?.openOnboarding(with: input)
    }

    func openMain(with userWalletModel: UserWalletModel) {
        coordinator?.openMain(with: userWalletModel)
    }
}

// MARK: - StoriesDelegate

extension WelcomeViewModel: StoriesDelegate {
    var isScanning: AnyPublisher<Bool, Never> {
        isScanningCard.eraseToAnyPublisher()
    }

    func openTokenList() {
        // For some reason the button can be tapped even after we've this flag to FALSE to disable it
        guard !isScanningCard.value else { return }

        Analytics.log(.buttonTokensList)
        coordinator?.openTokensList()
    }

    func openMail() {
        coordinator?.openMail(with: BaseDataCollector(), recipient: EmailConfig.default.recipient)
    }

    func openPromotion() {
        Analytics.log(.introductionProcessLearn)
        coordinator?.openPromotion()
    }

    func openShop() {
        coordinator?.openShop()
    }
}

// MARK: - IncomingActionResponder

extension WelcomeViewModel: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.scanCard()
        }

        switch action {
        case .start:
            return true
        default:
            return false
        }
    }
}
