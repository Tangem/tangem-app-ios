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
        let event: GeneralNotificationEvent = .walletLocked
        return .init(
            style: .tappable { [weak self] _ in
                self?.onLockedWalletNotificationTap()
            },
            severity: event.severity,
            settings: .init(event: event, dismissAction: nil)
        )
    }()

    lazy var singleWalletButtonsInfo: [FixedSizeButtonWithIconInfo] = TokenActionListBuilder()
        .buildActionsForLockedSingleWallet()
        .map {
            FixedSizeButtonWithIconInfo(
                title: $0.title,
                icon: $0.icon,
                disabled: true,
                style: .disabled,
                action: {}
            )
        }

    var footerViewModel: MainFooterViewModel?

    @Published
    private(set) var actionButtonsViewModel: ActionButtonsViewModel?

    private(set) lazy var bottomSheetFooterViewModel = MainBottomSheetFooterViewModel()

    let isMultiWallet: Bool

    private let userWalletModel: UserWalletModel
    private let contextData: AnalyticsContextData?

    private var canManageTokens: Bool { userWalletModel.config.hasFeature(.multiCurrency) }
    private weak var lockedUserWalletDelegate: MainLockedUserWalletDelegate?

    init(
        userWalletModel: UserWalletModel,
        isMultiWallet: Bool,
        lockedUserWalletDelegate: MainLockedUserWalletDelegate?
    ) {
        self.userWalletModel = userWalletModel
        self.isMultiWallet = isMultiWallet
        self.lockedUserWalletDelegate = lockedUserWalletDelegate

        contextData = userWalletModel.getAnalyticsContextData()

        if isMultiWallet {
            actionButtonsViewModel = makeActionButtonsViewModel()
        }

        Analytics.log(event: .mainNoticeWalletUnlock, params: contextData?.analyticsParams ?? [:])
    }

    private func onLockedWalletNotificationTap() {
        Analytics.log(event: .mainNoticeWalletUnlockTapped, params: contextData?.analyticsParams ?? [:])
        openUnlockSheet()
    }

    private func openUnlockSheet() {
        lockedUserWalletDelegate?.openUnlockUserWalletBottomSheet(for: userWalletModel)
    }
}

// MARK: - Action buttons

private extension LockedWalletMainContentViewModel {
    func makeActionButtonsViewModel() -> ActionButtonsViewModel? {
        return .init(
            coordinator: MainCoordinator(dismissAction: {}, popToRootAction: { _ in }),
            expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletModel: userWalletModel),
            userWalletModel: userWalletModel
        )
    }
}
