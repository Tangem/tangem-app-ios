//
//  PushNotificationsPermissionRequestViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class PushNotificationsPermissionRequestViewModel: ObservableObject, Identifiable {
    @Published private(set) var allowButtonTitle: String
    @Published private(set) var laterButtonTitle: String

    private let permissionManager: PushNotificationsPermissionManager

    private weak var delegate: PushNotificationsPermissionRequestDelegate?

    init(
        permissionManager: PushNotificationsPermissionManager,
        delegate: PushNotificationsPermissionRequestDelegate
    ) {
        self.permissionManager = permissionManager
        self.delegate = delegate

        allowButtonTitle = Localization.commonAllow
        laterButtonTitle = Localization.commonLater
    }

    func didTapAllow() {
        runTask(in: self) { viewModel in
            await viewModel.permissionManager.allowPermissionRequest()
            await runOnMain {
                viewModel.delegate?.didFinishPushNotificationOnboarding()
            }
        }
    }

    func didTapLater() {
        permissionManager.postponePermissionRequest()
        delegate?.didFinishPushNotificationOnboarding()
    }

    func didDismissSheet() {
        permissionManager.postponePermissionRequest()
    }
}
