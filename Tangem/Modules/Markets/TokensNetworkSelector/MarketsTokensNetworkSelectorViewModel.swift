//
//  MarketsTokensNetworkSelectorViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 21.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk
import TangemSdk

final class MarketsTokensNetworkSelectorViewModel: Identifiable, ObservableObject {
    // MARK: - Published Properties

    @Published var walletSelectorViewModel: MarketsWalletSelectorViewModel
    @Published var notificationInput: NotificationViewInput?

    @Published var tokenItemViewModels: [MarketsTokensNetworkSelectorItemViewModel] = []

    @Published var alert: AlertBinder?
    @Published var pendingAdd: [TokenItem] = []

    @Published var isSaving: Bool = false

    var isSaveDisabled: Bool {
        pendingAdd.isEmpty
    }

    var isShowWalletSelector: Bool {
        walletDataProvider.userWalletModels.count > 1
    }

    // MARK: - Private Implementation

    private var bag = Set<AnyCancellable>()
    private let alertBuilder = MarketsTokensNetworkSelectorAlertBuilder()

    private let walletDataProvider: MarketsWalletDataProvider
    private let coinModel: CoinModel

    // MARK: - Computed Properties

    var coinIconURL: URL {
        IconURLBuilder().tokenIconURL(id: coinModel.id)
    }

    var coinName: String {
        coinModel.name
    }

    var coinSymbol: String {
        coinModel.symbol
    }

    private var tokenItems: [TokenItem] {
        coinModel.items.map { $0.tokenItem }
    }

    // The cache of the proper state storage
    private var readonlyTokens: [TokenItem] = []

    private var selectedUserWalletModel: UserWalletModel? {
        walletDataProvider.selectedUserWalletModel
    }

    private var canTokenItemBeToggled: Bool {
        selectedUserWalletModel != nil
    }

    // MARK: - Init

    init(coinModel: CoinModel, walletDataProvider: MarketsWalletDataProvider) {
        self.coinModel = coinModel
        self.walletDataProvider = walletDataProvider

        walletSelectorViewModel = MarketsWalletSelectorViewModel(provider: walletDataProvider)

        bind()
    }

    // MARK: - Implementation

    func saveChangesOnTapAction() {
        guard let userTokensManager = selectedUserWalletModel?.userTokensManager else {
            return
        }

        applyChanges(with: userTokensManager)
    }

    // MARK: - Private Implementation

    private func bind() {
        walletDataProvider.selectedUserWalletModelPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, userWalletId in
                guard let userWalletModel = viewModel.walletDataProvider.userWalletModels.first(where: { $0.userWalletId == userWalletId }) else {
                    return
                }

                viewModel.setNeedSelectWallet(userWalletModel)
                viewModel.readonlyTokens = viewModel.tokenItems.filter { viewModel.isAdded($0) }
                viewModel.reloadSelectorItemsFromTokenItems()
            }
            .store(in: &bag)
    }

    private func reloadSelectorItemsFromTokenItems() {
        tokenItemViewModels = tokenItems
            .enumerated()
            .map { index, element in
                MarketsTokensNetworkSelectorItemViewModel(
                    tokenItem: element,
                    isReadonly: isReadonly(element),
                    isSelected: bindSelection(element),
                    position: .init(with: index, total: tokenItems.count)
                )
            }
    }

    private func applyChanges(with userTokensManager: UserTokensManager) {
        guard !isSaving else {
            return
        }

        isSaving = true

        userTokensManager.update(itemsToRemove: [], itemsToAdd: pendingAdd) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                self.isSaving = false

                if case .failure(let error) = result {
                    if !error.isUserCancelled {
                        self.alert = error.alertBinder
                    }

                    return
                }

                // Copy tokens to readonly state, which have been success added
                self.readonlyTokens.append(contentsOf: self.pendingAdd)
                self.pendingAdd = []
                self.updateSelectionByTokenItems()
            }
        }
    }

    private func onSelect(_ selected: Bool, _ tokenItem: TokenItem) throws {
        guard let userTokensManager = selectedUserWalletModel?.userTokensManager else {
            return
        }

        sendAnalyticsOnChangeTokenState(tokenIsSelected: selected, tokenItem: tokenItem)

        if selected {
            guard !isAdded(tokenItem) else { return }

            try userTokensManager.addTokenItemPrecondition(tokenItem)
            pendingAdd.append(tokenItem)
        } else {
            pendingAdd.remove(tokenItem)
        }
    }

    private func bindSelection(_ tokenItem: TokenItem) -> Binding<Bool> {
        let binding = Binding<Bool> { [weak self] in
            self?.isSelected(tokenItem) ?? false
        } set: { [weak self] isSelected in
            do {
                try self?.onSelect(isSelected, tokenItem)
            } catch {
                self?.displayAlertAndUpdateSelection(for: tokenItem, error: error)
            }
        }

        return binding
    }

    private func bindCopy() -> Binding<Bool> {
        let binding = Binding<Bool> {
            false
        } set: { _ in
            Toast(view: SuccessToast(text: Localization.contractAddressCopiedMessage))
                .present(
                    layout: .bottom(padding: 80),
                    type: .temporary()
                )
        }

        return binding
    }

    private func updateSelection(_ tokenItem: TokenItem) {
        tokenItemViewModels
            .first(where: { $0.tokenItem == tokenItem })?
            .updateSelection(with: bindSelection(tokenItem), isReadonly: isReadonly(tokenItem))
    }

    private func sendAnalyticsOnChangeTokenState(tokenIsSelected: Bool, tokenItem: TokenItem) {
        Analytics.log(event: .marketsTokenNetworkSelected, params: [.token: tokenItem.currencySymbol, .count: "\(pendingAdd.count)"])
    }

    private func setNeedSelectWallet(_ userWalletModel: UserWalletModel?) {
        Analytics.log(
            event: .manageTokensWalletSelected,
            params: [.source: Analytics.ParameterValue.mainToken.rawValue]
        )

        pendingAdd = []
        reloadSelectorItemsFromTokenItems()
    }

    private func updateSelectionByTokenItems() {
        coinModel.items
            .map { $0.tokenItem }
            .forEach { tokenItem in
                updateSelection(tokenItem)
            }
    }
}

// MARK: - Helpers

private extension MarketsTokensNetworkSelectorViewModel {
    func isAdded(_ tokenItem: TokenItem) -> Bool {
        if let userTokensManager = selectedUserWalletModel?.userTokensManager {
            return userTokensManager.contains(tokenItem)
        }

        return false
    }

    func isSelected(_ tokenItem: TokenItem) -> Bool {
        let isWaitingToBeAdded = pendingAdd.contains(tokenItem)
        let alreadyAdded = isAdded(tokenItem)

        return isWaitingToBeAdded || alreadyAdded
    }

    func isReadonly(_ tokenItem: TokenItem) -> Bool {
        readonlyTokens.contains(tokenItem) && isAdded(tokenItem)
    }
}

// MARK: - Alerts

private extension MarketsTokensNetworkSelectorViewModel {
    func displayAlertAndUpdateSelection(for tokenItem: TokenItem, error: Error?) {
        let okButton = Alert.Button.default(Text(Localization.commonOk)) {
            self.updateSelection(tokenItem)
        }

        alert = AlertBinder(alert: Alert(
            title: Text(Localization.commonAttention),
            message: Text(error?.localizedDescription ?? ""),
            dismissButton: okButton
        ))
    }

    func displayAlertAndUpdateSelection(for tokenItem: TokenItem, title: String, message: String) {
        let okButton = Alert.Button.default(Text(Localization.commonOk)) {
            self.updateSelection(tokenItem)
        }

        alert = AlertBinder(alert: Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: okButton
        ))
    }

    func displayWarningNotification(for event: WarningEvent) {
        let notificationsFactory = NotificationsFactory()

        notificationInput = notificationsFactory.buildNotificationInput(
            for: event,
            action: { _ in },
            buttonAction: { _, _ in },
            dismissAction: { _ in }
        )
    }
}
