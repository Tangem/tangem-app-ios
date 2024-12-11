//
//  VisaOnboardingApproveWalletSelectorView.swift
//  Tangem
//
//  Created by Andrew Son on 02.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

protocol VisaOnboardingApproveWalletSelectorDelegate: AnyObject {
    func useExternalWallet()
    func useTangemWallet()
}

final class VisaOnboardingApproveWalletSelectorViewModel: ObservableObject {
    @Published private(set) var selectedOption: VisaOnboardingApproveWalletSelectorItemView.Option = .tangemWallet

    let instructionNotificationInput: NotificationViewInput = .init(
        style: .plain,
        severity: .info,
        settings: .init(event: VisaNotificationEvent.onboardingAccountActivationInfo, dismissAction: nil)
    )

    private weak var delegate: VisaOnboardingApproveWalletSelectorDelegate?

    init(delegate: VisaOnboardingApproveWalletSelectorDelegate) {
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
}
