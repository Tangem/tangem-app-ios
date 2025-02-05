//
//  ActionButtonsSellViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 12.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class ActionButtonsSellViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.exchangeService) private var exchangeService: CombinedExchangeService & ExchangeService

    // MARK: - Published properties

    @Published var alert: AlertBinder?
    @Published var notificationInputs: [NotificationViewInput] = []
    @Published private(set) var state: SellTokensListState = .idle

    // MARK: - Child ViewModel

    let tokenSelectorViewModel: ActionButtonsTokenSelectorViewModel

    // MARK: - Private properties

    private weak var coordinator: ActionButtonsSellRoutable?

    private let userWalletModel: UserWalletModel
    private var bag = Set<AnyCancellable>()

    private lazy var notificationManager: some NotificationManager = {
        let notificationManager = ActionButtonsNotificationManager(
            destination: .sell($state.eraseToAnyPublisher())
        )

        notificationManager.setupManager(with: self)

        return notificationManager
    }()

    init(
        tokenSelectorViewModel: ActionButtonsTokenSelectorViewModel,
        coordinator: some ActionButtonsSellRoutable,
        userWalletModel: some UserWalletModel
    ) {
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel

        bind()
    }

    func handleViewAction(_ action: Action) {
        switch action {
        case .onAppear:
            ActionButtonsAnalyticsService.trackScreenOpened(.sell)
        case .close:
            ActionButtonsAnalyticsService.trackCloseButtonTap(source: .sell)
            coordinator?.dismiss()
        case .didTapToken(let token):
            handleTapToken(token)
        }
    }

    private func handleTapToken(_ token: ActionButtonsTokenSelectorItem) {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(
            for: .exchange
        ) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        ActionButtonsAnalyticsService.trackTokenClicked(.sell, tokenSymbol: token.infoProvider.tokenItem.currencySymbol)

        guard let url = makeSellUrl(from: token) else { return }

        coordinator?.openSellCrypto(at: url) { response in
            self.makeSendToSellModel(from: response, and: token.walletModel)
        }
    }

    private func bind() {
        exchangeService
            .sellInitializationPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, newState in
                if case .failed(.countryNotSupported) = newState {
                    viewModel.state = .regionalRestrictions
                } else {
                    viewModel.state = .idle
                }
            }
            .store(in: &bag)

        let makeNotificationPublisher = { [notificationManager] filter in
            notificationManager
                .notificationPublisher
                .removeDuplicates()
                .scan(([NotificationViewInput](), [NotificationViewInput]())) { prev, new in
                    (prev.1, new)
                }
                .filter(filter)
                .map(\.1)
        }

        // Publisher for showing new notifications with a delay to prevent unwanted animations
        makeNotificationPublisher { $1.count >= $0.count }
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        // Publisher for immediate updates when notifications are removed (e.g., from 2 to 0 or 1)
        // to fix 'jumping' animation bug
        makeNotificationPublisher { $1.count < $0.count }
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

// MARK: - Fabric methods

private extension ActionButtonsSellViewModel {
    func makeSendToSellModel(
        from response: String,
        and walletModel: WalletModel
    ) -> ActionButtonsSendToSellModel? {
        let exchangeUtility = makeExchangeCryptoUtility(for: walletModel)

        guard
            let sellCryptoRequest = exchangeUtility.extractSellCryptoRequest(from: response),
            var amountToSend = walletModel.wallet.amounts[walletModel.amountType]
        else {
            return nil
        }

        amountToSend.value = sellCryptoRequest.amount

        return .init(
            amountToSend: amountToSend,
            destination: sellCryptoRequest.targetAddress,
            tag: sellCryptoRequest.tag,
            walletModel: walletModel
        )
    }

    func makeSellUrl(from token: ActionButtonsTokenSelectorItem) -> URL? {
        let sellUrl = exchangeService.getSellUrl(
            currencySymbol: token.infoProvider.tokenItem.currencySymbol,
            amountType: token.walletModel.amountType,
            blockchain: token.walletModel.blockchainNetwork.blockchain,
            walletAddress: token.walletModel.defaultAddress
        )

        return sellUrl
    }

    func makeExchangeCryptoUtility(for walletModel: WalletModel) -> ExchangeCryptoUtility {
        return ExchangeCryptoUtility(
            blockchain: walletModel.blockchainNetwork.blockchain,
            address: walletModel.defaultAddress,
            amountType: walletModel.amountType
        )
    }
}

// MARK: - Notification

extension ActionButtonsSellViewModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {}
}

// MARK: - State

extension ActionButtonsSellViewModel {
    enum SellTokensListState {
        case idle
        case regionalRestrictions
    }
}

extension ActionButtonsSellViewModel {
    enum Action {
        case onAppear
        case close
        case didTapToken(ActionButtonsTokenSelectorItem)
    }
}
