//
//  VisaOnboardingApproveWalletSelectorView.swift
//  Tangem
//
//  Created by Andrew Son on 02.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemVisa

protocol VisaOnboardingRemoteStateProvider: AnyObject {
    func loadCurrentRemoteState() async throws -> VisaCardActivationRemoteState
}

protocol VisaOnboardingApproveWalletSelectorDelegate: VisaOnboardingAlertPresenter {
    func useExternalWallet()
    func useTangemWallet()
    @MainActor
    func proceedFromCurrentRemoteState() async
}

final class VisaOnboardingApproveWalletSelectorViewModel: ObservableObject {
    @Published private(set) var isLoadingRemoteState: Bool = false
    @Published private(set) var selectedOption: VisaOnboardingApproveWalletSelectorItemView.Option = .tangemWallet

    let instructionNotificationInput: NotificationViewInput = .init(
        style: .plain,
        severity: .info,
        settings: .init(event: VisaNotificationEvent.onboardingAccountActivationInfo, dismissAction: nil)
    )

    private weak var remoteStateProvider: VisaOnboardingRemoteStateProvider?
    private weak var delegate: VisaOnboardingApproveWalletSelectorDelegate?

    init(
        remoteStateProvider: VisaOnboardingRemoteStateProvider?,
        delegate: VisaOnboardingApproveWalletSelectorDelegate?
    ) {
        self.remoteStateProvider = remoteStateProvider
        self.delegate = delegate
    }

    func selectOption(_ option: VisaOnboardingApproveWalletSelectorItemView.Option) {
        selectedOption = option
    }

    func continueAction() {
        switch selectedOption {
        case .tangemWallet:
            delegate?.useTangemWallet()
        case .otherWallet:
            delegate?.useExternalWallet()
        }
    }

    private func navigateToExternalWalletConnectionIfNeeded() {
        isLoadingRemoteState = true
        runTask(in: self, isDetached: false) { viewModel in
            do {
                let currentRemoteState = try await viewModel.remoteStateProvider?.loadCurrentRemoteState()
                if currentRemoteState == .customerWalletSignatureRequired {
                    viewModel.delegate?.useExternalWallet()
                } else {
                    await viewModel.delegate?.proceedFromCurrentRemoteState()
                }
            } catch {
                VisaLogger.error(self, "Failed to load current remote state on Approve Wallet Selector", error: error)
                await viewModel.delegate?.showContactSupportAlert(for: error)
            }
        }
    }
}

extension VisaOnboardingApproveWalletSelectorViewModel: CustomStringConvertible {
    var description: String { objectDescription(self) }
}
