//
//  LockedWalletMainContentViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 16/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

protocol MainLockedUserWalletDelegate: AnyObject {
    func openUnlockUserWalletBottomSheet(for userWalletModel: UserWalletModel)
}

class LockedWalletMainContentViewModel: ObservableObject {
    lazy var lockedNotificationInput: NotificationViewInput = {
        let factory = NotificationsFactory()
        return .init(
            style: .tappable(action: { [weak self] _ in
                self?.onLockedWalletNotificationTap()
            }),
            settings: factory.lockedWalletNotificationSettings()
        )
    }()

    lazy var singleWalletButtonsInfo: [ButtonWithIconInfo] = TokenActionListBuilder()
        .buildActionsForLockedSingleWallet()
        .map {
            ButtonWithIconInfo(
                title: $0.title,
                icon: $0.icon,
                action: {},
                disabled: true
            )
        }

    var footerViewModel: MainFooterViewModel? {
        guard canManageTokens else { return nil }

        return MainFooterViewModel(
            isButtonDisabled: true,
            buttonTitle: Localization.mainManageTokens,
            buttonAction: {}
        )
    }

    let isMultiWallet: Bool

    private let userWalletModel: UserWalletModel
    private var canManageTokens: Bool { userWalletModel.isMultiWallet }
    private weak var lockedUserWalletDelegate: MainLockedUserWalletDelegate?

    init(
        userWalletModel: UserWalletModel,
        isMultiWallet: Bool,
        lockedUserWalletDelegate: MainLockedUserWalletDelegate?
    ) {
        self.userWalletModel = userWalletModel
        self.isMultiWallet = isMultiWallet
        self.lockedUserWalletDelegate = lockedUserWalletDelegate
    }

    private func onLockedWalletNotificationTap() {
        Analytics.log(.mainNoticeWalletLocked)
        openUnlockSheet()
    }

    private func openUnlockSheet() {
        lockedUserWalletDelegate?.openUnlockUserWalletBottomSheet(for: userWalletModel)
    }
}
