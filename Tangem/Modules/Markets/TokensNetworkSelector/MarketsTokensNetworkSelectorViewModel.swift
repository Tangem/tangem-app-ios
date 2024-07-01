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

    var isSaveDisabled: Bool {
        pendingAdd.isEmpty
    }

    // MARK: - Private Implementation

    private var bag = Set<AnyCancellable>()
    private let alertBuilder = MarketsTokensNetworkSelectorAlertBuilder()

    /// CoinId from parent data source embedded on selected UserWalletModel
    private let parentEmbeddedCoinId: String?
    private let dataSource: MarketsTokensNetworkDataSource

    private let coinId: String
    private let tokenItems: [TokenItem]

    private var selectedUserWalletModel: UserWalletModel? {
        dataSource.selectedUserWalletModel
    }

    private var canTokenItemBeToggled: Bool {
        selectedUserWalletModel != nil
    }

    // MARK: - Init

    init(
        parentDataSource: MarketsDataSource,
        coinId: String,
        tokenItems: [TokenItem]
    ) {
        self.coinId = coinId
        self.tokenItems = tokenItems
        parentEmbeddedCoinId = parentDataSource.defaultUserWalletModel?.embeddedCoinId

        dataSource = MarketsTokensNetworkDataSource(parentDataSource)
        walletSelectorViewModel = MarketsWalletSelectorViewModel(provider: dataSource)

        bind()
        setup()

        reloadSelectorItemsFromTokenItems()
    }

    // MARK: - Implementation

    func selectWalletActionDidTap() {
        Analytics.log(event: .manageTokensButtonChooseWallet, params: [:])
    }

    func displayNonNativeNetworkAlert() {
        Analytics.log(.manageTokensNoticeNonNativeNetworkClicked)

        let okButton = Alert.Button.default(Text(Localization.commonOk)) {}

        alert = AlertBinder(alert: Alert(
            title: Text(""),
            message: Text(Localization.manageTokensNetworkSelectorNonNativeInfo),
            dismissButton: okButton
        ))
    }

    // MARK: - Private Implementation

    private func bind() {
        dataSource.selectedUserWalletModelPublisher
            .sink { [weak self] userWalletId in
                guard let userWalletModel = self?.dataSource.userWalletModels.first(where: { $0.userWalletId == userWalletId }) else {
                    return
                }

                self?.setNeedSelectWallet(userWalletModel)
            }
            .store(in: &bag)
    }

    private func reloadSelectorItemsFromTokenItems() {
        tokenItemViewModels = tokenItems
            .map {
                .init(
                    id: $0.hashValue,
                    isMain: $0.isBlockchain,
                    iconName: $0.blockchain.iconName,
                    iconNameSelected: $0.blockchain.iconNameFilled,
                    networkName: $0.networkName,
                    tokenTypeName: nil,
                    contractAddress: $0.contractAddress,
                    isSelected: bindSelection($0),
                    isAvailable: canTokenItemBeToggled
                )
            }
    }

    /// This method that shows a configure notification input result if the condition is single currency by coinId
    private func setup() {
        guard dataSource.userWalletModels.isEmpty else {
            return
        }

        if parentEmbeddedCoinId != coinId {
            displayWarningNotification(for: .supportedOnlySingleCurrencyWallet)
        }
    }

    private func saveChanges() throws {
        guard let userTokensManager = dataSource.selectedUserWalletModel?.userTokensManager else {
            return
        }

        try userTokensManager.update(itemsToRemove: [], itemsToAdd: pendingAdd)
    }

    private func isAvailableTokenSelection() -> Bool {
        !dataSource.userWalletModels.isEmpty
    }

    private func onSelect(_ selected: Bool, _ tokenItem: TokenItem) throws {
        guard let userTokensManager = dataSource.selectedUserWalletModel?.userTokensManager else {
            return
        }

        if selected {
            try userTokensManager.addTokenItemPrecondition(tokenItem)
        }

        sendAnalyticsOnChangeTokenState(tokenIsSelected: selected, tokenItem: tokenItem)

        let alreadyAdded = isAdded(tokenItem)

        if selected {
            pendingAdd.append(tokenItem)
        } else {
            pendingAdd.remove(tokenItem)
        }

        try saveChanges()
    }

    private func bindSelection(_ tokenItem: TokenItem) -> Binding<Bool> {
        let binding = Binding<Bool> { [weak self] in
            self?.isSelected(tokenItem) ?? false
        } set: { [weak self] isSelected in
            if isSelected {
                self?.pendingAdd.remove(tokenItem)
            } else {
                self?.pendingAdd.append(tokenItem)
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
            .first(where: { $0.id == tokenItem.hashValue })?
            .updateSelection(with: bindSelection(tokenItem))
    }

    private func sendAnalyticsOnChangeTokenState(tokenIsSelected: Bool, tokenItem: TokenItem) {
        Analytics.log(event: .manageTokensSwitcherChanged, params: [
            .token: tokenItem.currencySymbol,
            .state: Analytics.ParameterValue.toggleState(for: tokenIsSelected).rawValue,
        ])
    }

    private func setNeedSelectWallet(_ userWalletModel: UserWalletModel?) {
        if selectedUserWalletModel?.userWalletId != userWalletModel?.userWalletId {
            Analytics.log(
                event: .manageTokensWalletSelected,
                params: [.source: Analytics.ParameterValue.mainToken.rawValue]
            )
        }

        pendingAdd = []

        reloadSelectorItemsFromTokenItems()
    }
}

// MARK: - Helpers

private extension MarketsTokensNetworkSelectorViewModel {
    func isTokenAvailable(_ tokenItem: TokenItem) -> Bool {
        guard let userTokensManager = dataSource.selectedUserWalletModel?.userTokensManager else {
            return false
        }

        do {
            try userTokensManager.addTokenItemPrecondition(tokenItem)
            return true
        } catch {
            return false
        }
    }

    func isAdded(_ tokenItem: TokenItem) -> Bool {
        if let userTokensManager = dataSource.selectedUserWalletModel?.userTokensManager {
            return userTokensManager.contains(tokenItem)
        }

        return parentEmbeddedCoinId == tokenItem.blockchain.coinId
    }

    func isSelected(_ tokenItem: TokenItem) -> Bool {
        let isWaitingToBeAdded = pendingAdd.contains(tokenItem)
        let alreadyAdded = isAdded(tokenItem)

        return isWaitingToBeAdded || alreadyAdded
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

private extension UserWalletModel {
    var embeddedCoinId: String? {
        config.embeddedBlockchain?.blockchainNetwork.blockchain.coinId
    }
}
