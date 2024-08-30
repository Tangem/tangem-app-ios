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

    let coinName: String
    let coinSymbol: String

    var isSaveDisabled: Bool {
        pendingAdd.isEmpty
    }

    var isShowWalletSelector: Bool {
        walletDataProvider.userWalletModels.count > 1
    }

    // MARK: - Private Implementation

    private var bag = Set<AnyCancellable>()
    private let alertBuilder = MarketsTokensNetworkSelectorAlertBuilder()

    private let coinId: String
    private let networks: [NetworkModel]

    private let walletDataProvider: MarketsWalletDataProvider

    private weak var coordinator: MarketsTokensNetworkRoutable?

    // MARK: - Computed Properties

    var coinIconURL: URL {
        IconURLBuilder().tokenIconURL(id: coinId)
    }

    private var tokenItems: [TokenItem] {
        guard let selectedUserWalletModel else {
            return []
        }

        let tokenItemMapper = TokenItemMapper(supportedBlockchains: selectedUserWalletModel.config.supportedBlockchains)

        let tokenItems = networks.compactMap {
            tokenItemMapper.mapToTokenItem(id: coinId, name: coinName, symbol: coinSymbol, network: $0)
        }

        return tokenItems
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

    init(data: InputData, walletDataProvider: MarketsWalletDataProvider, coordinator: MarketsTokensNetworkRoutable?) {
        coinId = data.coinId
        coinName = data.coinName
        coinSymbol = data.coinSymbol
        networks = data.networks

        self.walletDataProvider = walletDataProvider

        self.coordinator = coordinator

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

                // It is used to synchronize the execution of the target action and hide bottom sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.coordinator?.dissmis()
                }
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
        tokenItems.forEach {
            updateSelection($0)
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

extension MarketsTokensNetworkSelectorViewModel {
    struct InputData {
        let coinId: String
        let coinName: String
        let coinSymbol: String
        let networks: [NetworkModel]
    }
}
