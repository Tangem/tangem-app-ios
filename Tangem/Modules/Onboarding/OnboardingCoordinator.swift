//
//  OnboardingCoordinator.swift
//  Tangem
//
//  Created by Alexander Osokin on 14.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa

class OnboardingCoordinator: CoordinatorObject {
    var dismissAction: Action<OutputOptions>
    var popToRootAction: Action<PopToRootOptions>

    var isNavigationBarHidden: Bool {
        viewState?.isMain == false
    }

    var transitionAnimationValue: Bool {
        viewState?.isMain == false
    }

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Main view models

    @Published private(set) var viewState: ViewState? = nil

    // MARK: - Child view models

    @Published var warningBankCardViewModel: WarningBankCardViewModel? = nil
    @Published var modalWebViewModel: WebViewContainerViewModel? = nil
    @Published var accessCodeModel: OnboardingAccessCodeViewModel? = nil
    @Published var addressQrBottomSheetContentViewModel: AddressQrBottomSheetContentViewModel? = nil
    @Published var supportChatViewModel: SupportChatViewModel? = nil
    @Published var mailViewModel: MailViewModel? = nil

    // MARK: - Helpers

    // For non-dismissable presentation
    var onDismissalAttempt: () -> Void = {}

    // MARK: - Private

    private var options: OnboardingCoordinator.Options!
    private var safariHandle: SafariHandle?

    required init(dismissAction: @escaping Action<OutputOptions>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: OnboardingCoordinator.Options) {
        self.options = options
        let input = options.input
        switch input.steps {
        case .singleWallet:
            let model = SingleCardOnboardingViewModel(input: input, coordinator: self)
            onDismissalAttempt = model.backButtonAction
            viewState = .singleCard(model)
        case .twins:
            let model = TwinsOnboardingViewModel(input: input, coordinator: self)
            onDismissalAttempt = model.backButtonAction
            viewState = .twins(model)
        case .wallet:
            let model = WalletOnboardingViewModel(input: input, coordinator: self)
            onDismissalAttempt = model.backButtonAction
            viewState = .wallet(model)
        case .visa:
            let model = VisaOnboardingViewModel(
                input: input,
                visaActivationManager: VisaActivationManagerFactory().make(),
                coordinator: self
            )
            onDismissalAttempt = model.backButtonAction
            viewState = .visa(model)
        }

        Analytics.log(.onboardingStarted)
    }
}

// MARK: - Options

extension OnboardingCoordinator {
    enum DestinationOnFinish {
        case main
        case root
        case dismiss
    }

    struct Options {
        let input: OnboardingInput
        let destination: DestinationOnFinish
    }

    struct OutputOptions {
        let isSuccessful: Bool
    }
}

// MARK: - OnboardingTopupRoutable

extension OnboardingCoordinator: OnboardingTopupRoutable {
    func openCryptoShop(at url: URL, action: @escaping () -> Void) {
        safariHandle = safariManager.openURL(url) { [weak self] _ in
            self?.safariHandle = nil
            action()
        }
    }

    func openBankWarning(confirmCallback: @escaping () -> Void, declineCallback: @escaping () -> Void) {
        let delay = 0.6
        warningBankCardViewModel = .init(confirmCallback: { [weak self] in
            self?.warningBankCardViewModel = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                confirmCallback()
            }
        }, declineCallback: { [weak self] in
            self?.warningBankCardViewModel = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                declineCallback()
            }
        })
    }

    func openP2PTutorial() {
        modalWebViewModel = WebViewContainerViewModel(
            url: URL(string: "https://tangem.com/howtobuy.html")!,
            title: "",
            addLoadingIndicator: true,
            withCloseButton: false,
            urlActions: [:]
        )
    }

    func openQR(shareAddress: String, address: String, qrNotice: String) {
        addressQrBottomSheetContentViewModel = .init(shareAddress: shareAddress, address: address, qrNotice: qrNotice)
    }
}

// MARK: - WalletOnboardingRoutable

extension OnboardingCoordinator: WalletOnboardingRoutable {
    func openAccessCodeView(callback: @escaping (String) -> Void) {
        accessCodeModel = .init(successHandler: { [weak self] code in
            self?.accessCodeModel = nil
            callback(code)
        })
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = .init(logsComposer: logsComposer, recipient: recipient, emailType: emailType)
    }

    func openSupportChat(input: SupportChatInputModel) {
        Analytics.log(.chatScreenOpened)
        supportChatViewModel = SupportChatViewModel(input: input)
    }

    func openWebView(with url: URL) {
        modalWebViewModel = WebViewContainerViewModel(
            url: url,
            title: "",
            addLoadingIndicator: true,
            withCloseButton: true
        )
    }
}

// MARK: - OnboardingRoutable

extension OnboardingCoordinator: OnboardingRoutable {
    func onboardingDidFinish(userWalletModel: UserWalletModel?) {
        switch options.destination {
        case .main:
            if let userWalletModel {
                openMain(with: userWalletModel)
                return
            }

            dismiss(with: .init(isSuccessful: true))
        case .root:
            popToRoot()
        case .dismiss:
            dismiss(with: .init(isSuccessful: true))
        }
    }

    func closeOnboarding() {
        dismiss(with: .init(isSuccessful: false))
    }

    private func openMain(with userWalletModel: UserWalletModel) {
        let coordinator = MainCoordinator(popToRootAction: popToRootAction)

        let options = MainCoordinator.Options(userWalletModel: userWalletModel)
        coordinator.start(with: options)

        viewState = .main(coordinator)
    }
}

extension OnboardingCoordinator: VisaOnboardingRoutable {}

// MARK: ViewState

extension OnboardingCoordinator {
    enum ViewState {
        case singleCard(SingleCardOnboardingViewModel)
        case twins(TwinsOnboardingViewModel)
        case wallet(WalletOnboardingViewModel)
        case visa(VisaOnboardingViewModel)
        case main(MainCoordinator)

        var isMain: Bool {
            if case .main = self {
                return true
            }
            return false
        }
    }
}
