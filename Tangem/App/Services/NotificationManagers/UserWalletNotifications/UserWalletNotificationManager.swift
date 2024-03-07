//
//  UserWalletNotificationService.swift
//  Tangem
//
//  Created by Andrew Son on 26/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol NotificationTapDelegate: AnyObject {
    func didTapNotification(with id: NotificationViewId)
    func didTapNotificationButton(with id: NotificationViewId, action: NotificationButtonActionType)
}

/// Manager for handling Notifications related to UserWalletModel.
/// Don't forget to setup manager with delegate for proper notification handling
final class UserWalletNotificationManager {
    @Injected(\.deprecationService) private var deprecationService: DeprecationServicing
    @Injected(\.bannerPromotionService) private var bannerPromotionService: BannerPromotionService

    private let analyticsService: NotificationsAnalyticsService = .init()
    private let userWalletModel: UserWalletModel
    private let signatureCountValidator: SignatureCountValidator?
    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])

    private weak var delegate: NotificationTapDelegate?
    private var bag = Set<AnyCancellable>()
    private var numberOfPendingDerivations: Int = 0
    private var promotionUpdateTask: Task<Void, Never>?

    init(
        userWalletModel: UserWalletModel,
        signatureCountValidator: SignatureCountValidator?,
        contextDataProvider: AnalyticsContextDataProvider?
    ) {
        self.userWalletModel = userWalletModel
        self.signatureCountValidator = signatureCountValidator

        analyticsService.setup(with: self, contextDataProvider: contextDataProvider)
    }

    private func createNotifications() {
        let factory = NotificationsFactory()
        let action: NotificationView.NotificationAction = { [weak self] id in
            self?.delegate?.didTapNotification(with: id)
        }

        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            self?.delegate?.didTapNotificationButton(with: id, action: action)
        }

        let dismissAction: NotificationView.NotificationAction = weakify(self, forFunction: UserWalletNotificationManager.dismissNotification)

        var inputs: [NotificationViewInput] = []

        if !userWalletModel.validate() {
            inputs.append(
                factory.buildNotificationInput(
                    for: .backupErrors,
                    action: action,
                    buttonAction: buttonAction,
                    dismissAction: dismissAction
                )
            )
        }

        if userWalletModel.config.hasFeature(.multiCurrency) {
            setupTangemExpressPromotionNotification(dismissAction: dismissAction)
        }

        inputs.append(contentsOf: factory.buildNotificationInputs(
            for: deprecationService.deprecationWarnings,
            action: action,
            buttonAction: buttonAction,
            dismissAction: dismissAction
        ))

        // We need to remove legacyDerivation WarningEvent, because it must be shown in Manage tokens only
        let eventsWithoutDerivationWarning = userWalletModel.config.warningEvents.filter { $0 != .legacyDerivation }
        inputs.append(contentsOf: factory.buildNotificationInputs(
            for: eventsWithoutDerivationWarning,
            action: action,
            buttonAction: buttonAction,
            dismissAction: dismissAction
        ))

        if numberOfPendingDerivations > 0 {
            inputs.append(
                factory.buildNotificationInput(
                    for: .missingDerivation(numberOfNetworks: numberOfPendingDerivations),
                    action: action,
                    buttonAction: buttonAction,
                    dismissAction: dismissAction
                )
            )
        }

        if userWalletModel.config.hasFeature(.backup) {
            inputs.append(
                factory.buildNotificationInput(
                    for: .missingBackup,
                    action: action,
                    buttonAction: buttonAction,
                    dismissAction: dismissAction
                )
            )
        }

        notificationInputsSubject.send(inputs)

        validateHashesCount()
    }

    private func setupTangemExpressPromotionNotification(
        dismissAction: @escaping NotificationView.NotificationAction
    ) {
        promotionUpdateTask?.cancel()
        promotionUpdateTask = Task { [weak self] in
            guard let self, !Task.isCancelled else {
                return
            }

            guard let promotion = await bannerPromotionService.activePromotion(place: .main) else {
                notificationInputsSubject.value.removeAll { $0.settings.event is BannerNotificationEvent }
                return
            }

            let input = BannerPromotionNotificationFactory().buildMainBannerNotificationInput(
                promotion: promotion,
                dismissAction: dismissAction
            )

            guard !notificationInputsSubject.value.contains(where: { $0.id == input.id }) else {
                return
            }

            await runOnMain {
                self.notificationInputsSubject.value.insert(input, at: 0)
            }
        }
    }

    private func bind() {
        bag.removeAll()

        userWalletModel.updatePublisher
            .sink(receiveValue: weakify(self, forFunction: UserWalletNotificationManager.createNotifications))
            .store(in: &bag)

        userWalletModel.userTokensManager.derivationManager?
            .pendingDerivationsCount
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: weakify(self, forFunction: UserWalletNotificationManager.addMissingDerivationWarningIfNeeded(pendingDerivationsCount:)))
            .store(in: &bag)
    }

    // TODO: Move this logic into separate entity (IOS-4430)
    private func validateHashesCount() {
        let config = userWalletModel.config
        let cardSignedHashes = userWalletModel.totalSignedHashes
        let isMultiWallet = config.hasFeature(.multiCurrency)
        let canCountHashes = config.hasFeature(.signedHashesCounter)

        func didFinishCountingHashes() {
            AppLog.shared.debug("⚠️ Hashes counted")
        }

        guard !AppSettings.shared.validatedSignedHashesCards.contains(userWalletModel.userWalletId.stringValue) else {
            didFinishCountingHashes()
            return
        }

        guard canCountHashes else {
            recordUserWalletHashesCountValidation()
            didFinishCountingHashes()
            return
        }

        guard cardSignedHashes > 0 else {
            recordUserWalletHashesCountValidation()
            didFinishCountingHashes()
            return
        }

        let factory = NotificationsFactory()
        guard !isMultiWallet else {
            didFinishCountingHashes()
            return
        }

        guard let signatureCountValidator else {
            didFinishCountingHashes()
            let notification = factory.buildNotificationInput(
                for: .numberOfSignedHashesIncorrect,
                action: { [weak self] id in
                    self?.delegate?.didTapNotification(with: id)
                },
                buttonAction: { _, _ in },
                dismissAction: weakify(self, forFunction: UserWalletNotificationManager.dismissNotification(with:))
            )
            notificationInputsSubject.value.append(notification)
            return
        }

        var validatorSubscription: AnyCancellable?
        validatorSubscription = signatureCountValidator.validateSignatureCount(signedHashes: cardSignedHashes)
            .subscribe(on: DispatchQueue.global())
            .handleEvents(receiveCancel: {
                AppLog.shared.debug("⚠️ Hash counter subscription cancelled")
            })
            .receive(on: DispatchQueue.main)
            .receiveCompletion { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    let notification = factory.buildNotificationInput(
                        for: .numberOfSignedHashesIncorrect,
                        action: { id in self?.delegate?.didTapNotification(with: id) },
                        buttonAction: { _, _ in },
                        dismissAction: { id in self?.dismissNotification(with: id) }
                    )
                    self?.notificationInputsSubject.value.append(notification)
                }
                didFinishCountingHashes()

                withExtendedLifetime(validatorSubscription) {}
            }
    }

    private func addMissingDerivationWarningIfNeeded(pendingDerivationsCount: Int) {
        guard numberOfPendingDerivations != pendingDerivationsCount else {
            return
        }

        numberOfPendingDerivations = pendingDerivationsCount
        createNotifications()
    }

    private func recordUserWalletHashesCountValidation() {
        AppSettings.shared.validatedSignedHashesCards.append(userWalletModel.userWalletId.stringValue)
    }

    private func recordDeprecationNotificationDismissal() {
        deprecationService.didDismissSystemDeprecationWarning()
    }
}

extension UserWalletNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate

        createNotifications()
        bind()
    }

    func dismissNotification(with id: NotificationViewId) {
        guard let notification = notificationInputsSubject.value.first(where: { $0.id == id }) else {
            return
        }

        if let event = notification.settings.event as? WarningEvent {
            switch event {
            case .systemDeprecationTemporary, .systemDeprecationPermanent:
                recordDeprecationNotificationDismissal()
            case .numberOfSignedHashesIncorrect:
                recordUserWalletHashesCountValidation()
            default:
                break
            }
        }

        if let event = notification.settings.event as? BannerNotificationEvent {
            switch event {
            case .changelly:
                bannerPromotionService.hide(promotion: .changelly, on: .main)
            }
        }

        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}
