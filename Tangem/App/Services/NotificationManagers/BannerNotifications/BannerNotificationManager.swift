//
//  BannerNotificationManager.swift
//  Tangem
//
//  Created by Alexander Osokin on 05.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class BannerNotificationManager {
    @Injected(\.bannerPromotionService) private var bannerPromotionService: BannerPromotionService
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    private let analyticsService = NotificationsAnalyticsService()

    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private weak var delegate: NotificationTapDelegate?
    private var promotionUpdateTask: Task<Void, Never>?
    private let placement: BannerPromotionPlacement
    private let userWalletId: UserWalletId

    init(userWalletId: UserWalletId, placement: BannerPromotionPlacement, contextDataProvider: AnalyticsContextDataProvider?) {
        self.userWalletId = userWalletId
        self.placement = placement
        analyticsService.setup(with: self, contextDataProvider: contextDataProvider)
    }

    private func setupRing() {
        guard AppSettings.shared.userWalletIdsWithRing.contains(userWalletId.stringValue) else {
            return
        }

        switch placement {
        case .main:
            setupPromotionNotification(programName: .ring)
        case .tokenDetails:
            break
        }
    }

    private func setupPromotionNotification(programName: PromotionProgramName) {
        promotionUpdateTask?.cancel()

        promotionUpdateTask = runTask(in: self) { manager in
            guard !Task.isCancelled else {
                return
            }

            let placement = manager.placement

            guard let promotion = await manager.bannerPromotionService.activePromotion(promotion: programName, on: placement) else {
                manager.notificationInputsSubject.value.removeAll { $0.id == programName.hashValue }
                return
            }

            if Task.isCancelled {
                return
            }

            let factory = BannerNotificationFactory()

            let dismissAction: NotificationView.NotificationAction = { [weak manager, placement] id in
                manager?.bannerPromotionService.hide(promotion: programName, on: placement)
                manager?.dismissNotification(with: id)

                Analytics.log(
                    .promotionBannerClicked,
                    params:
                    [
                        .programName: programName.analyticsValue,
                        .source: placement.analyticsValue,
                        .action: .closed,
                    ]
                )
            }

            let buttonAction: NotificationView.NotificationButtonTapAction = { [weak manager, placement] id, action in
                manager?.delegate?.didTapNotification(with: id, action: action)
                manager?.bannerPromotionService.hide(promotion: programName, on: placement)
                manager?.dismissNotification(with: id)

                Analytics.log(
                    .promotionBannerClicked,
                    params:
                    [
                        .programName: programName.analyticsValue,
                        .source: placement.analyticsValue,
                        .action: .clicked,
                    ]
                )
            }

            let input = factory.buildBannerNotificationInput(
                promotion: promotion,
                placement: placement,
                buttonAction: buttonAction,
                dismissAction: dismissAction
            )

            await runOnMain {
                if Task.isCancelled {
                    return
                }

                guard !manager.notificationInputsSubject.value.contains(where: { $0.id == input.id }) else {
                    return
                }

                manager.notificationInputsSubject.value.insert(input, at: 0)
            }
        }
    }
}

extension BannerNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate
        setupRing()
    }

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}
