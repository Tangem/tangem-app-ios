//
//  SingleWalletNotificationManager.swift
//  Tangem
//
//  Created by Andrew Son on 29/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk

final class SingleTokenNotificationManager {
    @Injected(\.bannerPromotionService) private var bannerPromotionService: BannerPromotionService
    private let analyticsService: NotificationsAnalyticsService = .init()

    private let walletModel: WalletModel
    private let walletModelsManager: WalletModelsManager
    private let expressDestinationService: ExpressDestinationService?
    private weak var delegate: NotificationTapDelegate?

    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])

    private var rentFeeNotification: NotificationViewInput?
    private var bag: Set<AnyCancellable> = []
    private var notificationsUpdateTask: Task<Void, Never>?
    private var promotionUpdateTask: Task<Void, Never>?

    init(
        walletModel: WalletModel,
        walletModelsManager: WalletModelsManager,
        expressDestinationService: ExpressDestinationService?,
        contextDataProvider: AnalyticsContextDataProvider?
    ) {
        self.walletModel = walletModel
        self.walletModelsManager = walletModelsManager
        self.expressDestinationService = expressDestinationService

        analyticsService.setup(with: self, contextDataProvider: contextDataProvider)
    }

    private func bind() {
        bag = []

        walletModel
            .walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.notificationsUpdateTask?.cancel()

                switch state {
                case .failed:
                    self?.setupNetworkUnreachable()
                case .noAccount(let message, _):
                    self?.setupNoAccountNotification(with: message)
                case .loading, .created:
                    break
                case .idle, .noDerivation:
                    self?.setupLoadedStateNotifications()
                }
            }
            .store(in: &bag)
    }

    private func setupLoadedStateNotifications() {
        let factory = NotificationsFactory()

        var events = [TokenNotificationEvent]()
        if let existentialWarning = walletModel.existentialDepositWarning {
            events.append(.existentialDepositWarning(message: existentialWarning))
        }

        if case .solana = walletModel.tokenItem.blockchain,
           !walletModel.isZeroAmount {
            events.append(.solanaHighImpact)
        }

        if case .binance = walletModel.tokenItem.blockchain {
            events.append(.bnbBeaconChainRetirement)
        }

        if let sendingRestrictions = walletModel.sendingRestrictions {
            let isFeeCurrencyPurchaseAllowed = walletModelsManager.walletModels.contains {
                $0.tokenItem == walletModel.feeTokenItem && $0.blockchainNetwork == walletModel.blockchainNetwork
            }

            if let event = TokenNotificationEvent.event(for: sendingRestrictions, isFeeCurrencyPurchaseAllowed: isFeeCurrencyPurchaseAllowed) {
                events.append(event)
            }
        }

        let inputs = events.map {
            factory.buildNotificationInput(
                for: $0,
                buttonAction: { [weak self] id, actionType in
                    self?.delegate?.didTapNotificationButton(with: id, action: actionType)
                },
                dismissAction: { [weak self] id in
                    self?.dismissNotification(with: id)
                }
            )
        }

        notificationInputsSubject.send(inputs)

        setupRentFeeNotification()
        setupTangemExpressPromotionNotification()
    }

    private func setupRentFeeNotification() {
        if let rentFeeNotification {
            notificationInputsSubject.value.append(rentFeeNotification)
        }

        notificationsUpdateTask?.cancel()
        notificationsUpdateTask = Task { [weak self] in
            guard
                let rentInput = await self?.loadRentNotificationIfNeeded(),
                let self
            else {
                return
            }

            if Task.isCancelled {
                return
            }

            if !notificationInputsSubject.value.contains(where: { $0.id == rentInput.id }) {
                await runOnMain {
                    self.rentFeeNotification = rentInput
                    self.notificationInputsSubject.value.append(rentInput)
                }
            }
        }
    }

    private func setupTangemExpressPromotionNotification() {
        promotionUpdateTask?.cancel()
        promotionUpdateTask = Task { [weak self] in
            guard let self, let expressDestinationService, !Task.isCancelled else {
                return
            }

            guard let promotion = await bannerPromotionService.activePromotion(promotion: .changelly, on: .tokenDetails) else {
                notificationInputsSubject.value.removeAll { $0.settings.event is BannerNotificationEvent }
                return
            }

            let factory = BannerPromotionNotificationFactory()
            let button = factory.buildNotificationButton(actionType: .exchange) { [weak self] id, actionType in
                self?.delegate?.didTapNotificationButton(with: id, action: actionType)
                self?.dismissNotification(with: id)
            }

            let input = factory.buildBannerNotificationInput(
                promotion: promotion,
                button: button,
                dismissAction: { [weak self] id in
                    self?.dismissNotification(with: id)
                }
            )

            guard await expressDestinationService.canBeSwapped(wallet: walletModel) else {
                notificationInputsSubject.value.removeAll { $0.id == input.id }
                return
            }

            guard !notificationInputsSubject.value.contains(where: { $0.id == input.id }) else {
                return
            }

            await runOnMain {
                self.notificationInputsSubject.value.insert(input, at: 0)
            }
        }
    }

    private func setupNetworkUnreachable() {
        let factory = NotificationsFactory()
        notificationInputsSubject
            .send([
                factory.buildNotificationInput(
                    for: .networkUnreachable(currencySymbol: walletModel.blockchainNetwork.blockchain.currencySymbol),
                    dismissAction: weakify(self, forFunction: SingleTokenNotificationManager.dismissNotification(with:))
                ),
            ])
    }

    private func setupNoAccountNotification(with message: String) {
        // Skip displaying the BEP2 account creation top-up notification
        // since it will be deprecated shortly due to the network shutdown
        if case .binance = walletModel.tokenItem.blockchain {
            return
        }

        let factory = NotificationsFactory()
        let event = TokenNotificationEvent.noAccount(message: message)

        notificationInputsSubject
            .send([
                factory.buildNotificationInput(
                    for: event,
                    buttonAction: { [weak self] id, actionType in
                        self?.delegate?.didTapNotificationButton(with: id, action: actionType)
                    },
                    dismissAction: { [weak self] id in
                        self?.dismissNotification(with: id)
                    }
                ),
            ])
    }

    private func loadRentNotificationIfNeeded() async -> NotificationViewInput? {
        guard walletModel.hasRent else { return nil }

        guard let rentMessage = try? await walletModel.updateRentWarning().async() else {
            return nil
        }

        if Task.isCancelled {
            return nil
        }

        let factory = NotificationsFactory()
        let input = factory.buildNotificationInput(
            for: .rentFee(rentMessage: rentMessage),
            dismissAction: weakify(self, forFunction: SingleTokenNotificationManager.dismissNotification(with:))
        )
        return input
    }
}

extension SingleTokenNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate

        setupLoadedStateNotifications()
        bind()
    }

    func dismissNotification(with id: NotificationViewId) {
        guard let notification = notificationInputsSubject.value.first(where: { $0.id == id }) else {
            return
        }

        guard let event = notification.settings.event as? BannerNotificationEvent else {
            return
        }

        switch event {
        case .changelly:
            Analytics.log(.swapPromoButtonClose)
            bannerPromotionService.hide(promotion: .changelly, on: .tokenDetails)
        case .travala:
            bannerPromotionService.hide(promotion: .travala, on: .tokenDetails)
        }

        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}
