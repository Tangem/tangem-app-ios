//
//  AccessCodeRecoverySettingsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 06/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class AccessCodeRecoverySettingsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var viewModels: [DefaultSelectableRowViewModel<Bool>] = []
    @Published var isUserCodeRecoveryAllowed: Bool
    @Published var errorAlert: AlertBinder?

    var actionButtonDisabled: Bool {
        isUserCodeRecoveryAllowed == recoveryInteractor.isUserCodeRecoveryAllowed
    }

    private let recoveryInteractor: UserCodeRecovering

    init(with recoveryInteractor: UserCodeRecovering) {
        self.recoveryInteractor = recoveryInteractor
        isUserCodeRecoveryAllowed = recoveryInteractor.isUserCodeRecoveryAllowed
        setupViews()
    }

    func actionButtonDidTap() {
        isLoading = true

        recoveryInteractor.toggleUserCodeRecoveryAllowed { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let newValue):
                Analytics.log(.cardSettingsAccessCodeRecoveryChanged, params: [.status: newValue ? .enabled : .disabled])
            case .failure(let error):
                if error.isUserCancelled {
                    break
                }

                errorAlert = error.alertBinder
            }

            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }

    private func setupViews() {
        viewModels = [
            DefaultSelectableRowViewModel(
                id: true,
                title: Localization.commonEnabled,
                subtitle: Localization.cardSettingsAccessCodeRecoveryEnabledDescription
            ),
            DefaultSelectableRowViewModel(
                id: false,
                title: Localization.commonDisabled,
                subtitle: Localization.cardSettingsAccessCodeRecoveryDisabledDescription
            ),
        ]
    }
}
