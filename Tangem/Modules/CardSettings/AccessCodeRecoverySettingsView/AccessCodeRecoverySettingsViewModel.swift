//
//  AccessCodeRecoverySettingsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 06/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemSdk

protocol AccessCodeRecoverySettingsProvider {
    var accessCodeRecoveryEnabled: Bool { get }
    func setAccessCodeRecovery(to enabled: Bool, _ completionHandler: @escaping (Result<Void, TangemSdkError>) -> Void)
}

class AccessCodeRecoverySettingsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var viewModels: [DefaultSelectableRowViewModel<Bool>] = []
    @Published var accessCodeRecoveryEnabled: Bool
    @Published var errorAlert: AlertBinder?

    var actionButtonDisabled: Bool {
        accessCodeRecoveryEnabled == settingsProvider.accessCodeRecoveryEnabled
    }

    private let settingsProvider: AccessCodeRecoverySettingsProvider

    init(settingsProvider: AccessCodeRecoverySettingsProvider) {
        self.settingsProvider = settingsProvider
        accessCodeRecoveryEnabled = settingsProvider.accessCodeRecoveryEnabled
        setupViews()
    }

    func actionButtonDidTap() {
        isLoading = true
        settingsProvider.setAccessCodeRecovery(to: accessCodeRecoveryEnabled) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                Analytics.log(.cardSettingsAccessCodeRecoveryChanged, params: [.status: accessCodeRecoveryEnabled ? .enabled : .disabled])
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
