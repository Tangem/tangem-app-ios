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
    @Published var isScanningCard: Bool = false
    @Published var error: AlertBinder?
    @Published var storiesModel: StoriesViewModel = .init()

    private var storiesModelSubscription: AnyCancellable?
    private var shouldScanOnAppear: Bool = false

    private unowned let coordinator: WelcomeRoutable

    init(shouldScanOnAppear: Bool, coordinator: WelcomeRoutable) {
        self.shouldScanOnAppear = shouldScanOnAppear
        self.coordinator = coordinator
        storiesModelSubscription = storiesModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.objectWillChange.send()
            })
    }

    func scanCardTapped() {
        scanCard()
    }

    func tryAgain() {
        scanCard()
    }

    func requestSupport() {
        Analytics.log(.buttonRequestSupport)
        failedCardScanTracker.resetCounter()
        openMail()
    }

    func orderCard() {
        // For some reason the button can be tapped even after we've this flag to FALSE to disable it
        guard !isScanningCard else { return }

        openShop()
        Analytics.log(.buttonBuyCards)
    }

    func onAppear() {
        Analytics.log(.introductionProcessOpened)
        incomingActionManager.becomeFirstResponder(self)
    }

    func onDidAppear() {
        if shouldScanOnAppear {
            DispatchQueue.main.async {
                self.scanCard()
            }
        }
    }

    func onDisappear() {
        incomingActionManager.resignFirstResponder(self)
    }

    private func scanCard() {
        isScanningCard = true
        Analytics.beginLoggingCardScan(source: .welcome)

        userWalletRepository.unlock(with: .card(userWallet: nil)) { [weak self] result in
            self?.isScanningCard = false

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
                showTroubleshootingView = true
            case .onboarding(let input):
                openOnboarding(with: input)
            case .error(let error):
                self.error = error.alertBinder
            case .success(let cardModel), .partial(let cardModel, _): // partial unlock is impossible in this case
                Analytics.log(event: .signedIn, params: [
                    .signInType: Analytics.ParameterValue.signInTypeCard.rawValue,
                    .walletsCount: "1", // we don't have any saved wallets, just log one
                ])
                openMain(with: cardModel)
            }
        }
    }
}

// MARK: - Navigation

extension WelcomeViewModel {
    func openMail() {
        coordinator.openMail(with: failedCardScanTracker, recipient: EmailConfig.default.recipient)
    }

    func openPromotion() {
        coordinator.openPromotion()
    }

    func openTokensList() {
        // For some reason the button can be tapped even after we've this flag to FALSE to disable it
        guard !isScanningCard else { return }

        Analytics.log(.buttonTokensList)
        coordinator.openTokensList()
    }

    func openShop() {
        coordinator.openShop()
    }

    func openOnboarding(with input: OnboardingInput) {
        coordinator.openOnboarding(with: input)
    }

    func openMain(with cardModel: CardViewModel) {
        coordinator.openMain(with: cardModel)
    }
}

// MARK: - WelcomeViewLifecycleListener

extension WelcomeViewModel: WelcomeViewLifecycleListener {
    func resignActve() {
        storiesModel.resignActve()
    }

    func becomeActive() {
        storiesModel.becomeActive()
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
        case .walletConnect:
            return false
        }
    }
}
