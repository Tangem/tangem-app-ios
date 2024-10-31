//
//  UserWalletNotificationManager.swift
//  Tangem
//
//  Created by Andrew Son on 26/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol NotificationTapDelegate: AnyObject {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType)
}

/// Manager for handling Notifications related to UserWalletModel.
/// Don't forget to setup manager with delegate for proper notification handling
final class UserWalletNotificationManager {
    @Injected(\.deprecationService) private var deprecationService: DeprecationServicing

    private let analyticsService: NotificationsAnalyticsService = .init()
    private let userWalletModel: UserWalletModel
    private let signatureCountValidator: SignatureCountValidator?
    private let rateAppController: RateAppNotificationController
    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])

    private weak var delegate: NotificationTapDelegate?
    private var bag = Set<AnyCancellable>()
    private var numberOfPendingDerivations: Int = 0

    private var showAppRateNotification = false
    private var shownAppRateNotificationId: NotificationViewId?

    init(
        userWalletModel: UserWalletModel,
        signatureCountValidator: SignatureCountValidator?,
        rateAppController: RateAppNotificationController,
        contextDataProvider: AnalyticsContextDataProvider?
    ) {
        self.userWalletModel = userWalletModel
        self.signatureCountValidator = signatureCountValidator
        self.rateAppController = rateAppController

        analyticsService.setup(with: self, contextDataProvider: contextDataProvider)
    }

    private func createNotifications() {
        let factory = NotificationsFactory()
        let action: NotificationView.NotificationAction = { [weak self] id in
            self?.delegate?.didTapNotification(with: id, action: .empty)
        }

        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            self?.delegate?.didTapNotification(with: id, action: action)
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

        inputs.append(contentsOf: factory.buildNotificationInputs(
            for: deprecationService.deprecationWarnings,
            action: action,
            buttonAction: buttonAction,
            dismissAction: dismissAction
        ))

        // We need to remove legacyDerivation WarningEvent, because it must be shown in Manage tokens only
        let eventsWithoutDerivationWarning = userWalletModel.config.generalNotificationEvents.filter { $0 != .legacyDerivation }
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

        showAppRateNotificationIfNeeded()

        validateHashesCount()
    }

    private func hideNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }

    private func showAppRateNotificationIfNeeded() {
        guard showAppRateNotification else {
            hideShownAppRateNotificationIfNeeded()
            return
        }

        let factory = NotificationsFactory()

        let action: NotificationView.NotificationAction = { [weak self] id in
            self?.delegate?.didTapNotification(with: id, action: .empty)
        }

        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            self?.delegate?.didTapNotification(with: id, action: action)
        }

        let dismissAction: NotificationView.NotificationAction = weakify(self, forFunction: UserWalletNotificationManager.dismissNotification)

        let input = factory.buildNotificationInput(
            for: .rateApp,
            action: action,
            buttonAction: buttonAction,
            dismissAction: dismissAction
        )
        shownAppRateNotificationId = input.id

        addInputIfNeeded(input)
    }

    private func hideShownAppRateNotificationIfNeeded() {
        guard let shownAppRateNotificationId else {
            return
        }

        hideNotification(with: shownAppRateNotificationId)
        self.shownAppRateNotificationId = nil
    }

    private func addInputIfNeeded(_ input: NotificationViewInput) {
        guard !notificationInputsSubject.value.contains(where: { $0.id == input.id }) else {
            return
        }

        notificationInputsSubject.value.insert(input, at: 0)
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

        rateAppController
            .showAppRateNotificationPublisher
            .withWeakCaptureOf(self)
            .sink(receiveValue: { manager, shouldShow in
                manager.showAppRateNotification = shouldShow
                manager.showAppRateNotificationIfNeeded()
            })
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
                    self?.delegate?.didTapNotification(with: id, action: .empty)
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
                        action: { id in self?.delegate?.didTapNotification(with: id, action: .empty) },
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

        if let event = notification.settings.event as? GeneralNotificationEvent {
            switch event {
            case .systemDeprecationTemporary, .systemDeprecationPermanent:
                recordDeprecationNotificationDismissal()
            case .numberOfSignedHashesIncorrect:
                recordUserWalletHashesCountValidation()
            case .rateApp:
                rateAppController.dismissAppRate()
            default:
                break
            }
        }

        hideNotification(with: id)
    }
}
