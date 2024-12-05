//
//  VisaOnboardingActivationWalletSelectorViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 02.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

protocol VisaOnboardingWalletSelectorDelegate: AnyObject {
    func useExternalWallet()
    func useTangemWallet()
}

final class VisaOnboardingActivationWalletSelectorViewModel: ObservableObject {
    @Published private(set) var selectedOption: VisaOnboardingActivationWalletSelectorItemView.Option = .tangemWallet

    let instructionNotificationInput: NotificationViewInput = .init(
        style: .plain,
        severity: .info,
        settings: .init(event: VisaNotificationEvent.onboardingAccountActivationInfo, dismissAction: nil)
    )

    private weak var delegate: VisaOnboardingWalletSelectorDelegate?

    init(delegate: VisaOnboardingWalletSelectorDelegate) {
        self.delegate = delegate
    }

    func selectOption(_ option: VisaOnboardingActivationWalletSelectorItemView.Option) {
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
