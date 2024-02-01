//
//  CommonRateAppController.swift
//  Tangem
//
//  Created by Andrey Fedorov on 22.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class CommonRateAppController {
    private let rateAppService: RateAppService
    private let userWalletModel: UserWalletModel
    private unowned let coordinator: RateAppRoutable

    private var bag: Set<AnyCancellable> = []

    init(
        rateAppService: RateAppService,
        userWalletModel: UserWalletModel,
        coordinator: RateAppRoutable
    ) {
        self.rateAppService = rateAppService
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
    }

    private func handleRateAppAction(_ action: RateAppAction) {
        coordinator.closeAppRateDialog()

        switch action {
        case .openAppRateDialog:
            let viewModel = RateAppBottomSheetViewModel { [weak self] response in
                self?.rateAppService.respondToRateAppDialog(with: response)
            }
            coordinator.openAppRateDialog(with: viewModel)
        case .openFeedbackMailWithEmailType(let emailType):
            let userWallet = userWalletModel
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.feedbackRequestDelay) { [weak self] in
                let collector = NegativeFeedbackDataCollector(userWalletEmailData: userWallet.emailData)
                let recipient = userWallet.config.emailConfig?.recipient ?? EmailConfig.default.recipient
                self?.coordinator.openFeedbackMail(with: collector, emailType: emailType, recipient: recipient)
            }
        case .openAppStoreReview:
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.feedbackRequestDelay) { [weak self] in
                self?.coordinator.openAppStoreReview()
            }
        }
    }
}

// MARK: - RateAppController protocol conformance

extension CommonRateAppController: RateAppController {
    func bind(
        isPageSelectedPublisher: some Publisher<Bool, Never>,
        notificationsPublisher: some Publisher<[NotificationViewInput], Never>
    ) {
        let isBalanceLoadedPublisher = userWalletModel
            .totalBalancePublisher
            .map { $0.value != nil }
            .removeDuplicates()

        Publishers.CombineLatest3(isPageSelectedPublisher, isBalanceLoadedPublisher, notificationsPublisher)
            .map { isPageSelected, isBalanceLoaded, notifications in
                return RateAppRequest(
                    isLocked: false,
                    isSelected: isPageSelected,
                    isBalanceLoaded: isBalanceLoaded,
                    displayedNotifications: notifications
                )
            }
            .withWeakCaptureOf(self)
            .sink { controller, rateAppRequest in
                controller.rateAppService.requestRateAppIfAvailable(with: rateAppRequest)
            }
            .store(in: &bag)

        userWalletModel
            .totalBalancePublisher
            .compactMap { $0.value }
            .withWeakCaptureOf(self)
            .sink { controller, _ in
                let walletModels = controller.userWalletModel.walletModelsManager.walletModels
                controller.rateAppService.registerBalances(of: walletModels)
            }
            .store(in: &bag)

        rateAppService
            .rateAppAction
            .withWeakCaptureOf(self)
            .sink { controller, rateAppAction in
                controller.handleRateAppAction(rateAppAction)
            }
            .store(in: &bag)
    }
}

// MARK: - Constants

private extension CommonRateAppController {
    private enum Constants {
        static let feedbackRequestDelay = 0.7
    }
}
