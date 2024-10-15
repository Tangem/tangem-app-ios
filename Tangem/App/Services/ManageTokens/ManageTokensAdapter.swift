//
//  ManageTokensAdapter.swift
//  Tangem
//
//  Created by Andrew Son on 27/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt
import TangemSdk
import BlockchainSdk

class ManageTokensAdapter {
    private let longHashesSupported: Bool
    private let existingCurves: [EllipticCurve]
    private let userTokensManager: UserTokensManager
    private let loader: TokensListDataLoader

    // This parameter is required due to the fact that the adapter is used in various places
    private let analyticsSourceRawValue: String

    private let listItemsViewModelsSubject = CurrentValueSubject<[ManageTokensListItemViewModel], Never>([])
    private let alertSubject = CurrentValueSubject<AlertBinder?, Never>(nil)
    private let isPendingListsEmptySubject = CurrentValueSubject<Bool, Never>(true)

    private var pendingAdd: [TokenItem] = []
    private var pendingRemove: [TokenItem] = []

    private var expandedCoinIds: Set<String> = []

    private var bag = Set<AnyCancellable>()

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    var listItemsViewModelsPublisher: some Publisher<[ManageTokensListItemViewModel], Never> {
        listItemsViewModelsSubject
    }

    var alertPublisher: some Publisher<AlertBinder?, Never> {
        alertSubject
    }

    var isPendingListsEmptyPublisher: some Publisher<Bool, Never> {
        isPendingListsEmptySubject
    }

    init(settings: Settings) {
        longHashesSupported = settings.longHashesSupported
        existingCurves = settings.existingCurves
        userTokensManager = settings.userTokensManager
        loader = TokensListDataLoader(supportedBlockchains: settings.supportedBlockchains)
        analyticsSourceRawValue = settings.analyticsSourceRawValue

        bind()
    }

    func saveChanges(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        userTokensManager.update(
            itemsToRemove: pendingRemove,
            itemsToAdd: pendingAdd
        ) { [weak self] result in
            guard let self else {
                return
            }

            // Send analytics event with parameters for success added tokens
            if case .success = result {
                let analyticsParams: [Analytics.ParameterKey: String] = [
                    .count: "\(pendingAdd.count)",
                    .source: analyticsSourceRawValue,
                ]

                Analytics.log(event: .manageTokensTokenAdded, params: analyticsParams)
            }

            completion(result)
        }
    }

    func resetAdapter() {
        pendingAdd = []
        pendingRemove = []
        isPendingListsEmptySubject.send(true)
        expandedCoinIds.removeAll()
    }

    func fetch(_ text: String) {
        if text != loader.lastSearchTextValue {
            expandedCoinIds.removeAll()
        }

        loader.fetch(text)
    }
}

private extension ManageTokensAdapter {
    func bind() {
        loader.$items
            .withWeakCaptureOf(self)
            .map { adapter, items -> [ManageTokensListItemViewModel] in
                // Send analytics event for empty search tokens
                adapter.sendIfNeededEmptySearchValueAnalyticsEvent()

                let viewModels = items.compactMap(adapter.mapToListItemViewModel(coinModel:))
                viewModels.forEach { $0.update(expanded: adapter.bindExpanded($0.coinId)) }
                return viewModels
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.value, on: listItemsViewModelsSubject, ownership: .weak)
            .store(in: &bag)
    }

    func isAdded(_ tokenItem: TokenItem) -> Bool {
        return userTokensManager.contains(tokenItem)
    }

    func canRemove(_ tokenItem: TokenItem) -> Bool {
        return userTokensManager.canRemove(tokenItem)
    }

    func isSelected(_ tokenItem: TokenItem) -> Bool {
        let isWaitingToBeAdded = pendingAdd.contains(tokenItem)
        let isWaitingToBeRemoved = pendingRemove.contains(tokenItem)
        let alreadyAdded = isAdded(tokenItem)

        if isWaitingToBeRemoved {
            return false
        }

        return isWaitingToBeAdded || alreadyAdded
    }

    func onSelect(_ selected: Bool, _ tokenItem: TokenItem) {
        if selected {
            if tokenItem.hasLongHashes, !longHashesSupported {
                displayAlertAndUpdateSelection(
                    for: tokenItem,
                    title: Localization.commonAttention,
                    message: Localization.alertManageTokensUnsupportedMessage(tokenItem.blockchain.displayName)
                )

                return
            }

            if !existingCurves.contains(tokenItem.blockchain.curve) {
                displayAlertAndUpdateSelection(
                    for: tokenItem,
                    title: Localization.commonAttention,
                    message: Localization.alertManageTokensUnsupportedCurveMessage(tokenItem.blockchain.displayName)
                )

                return
            }
        }

        sendAnalyticsOnChangeTokenState(tokenIsSelected: selected, tokenItem: tokenItem)

        let alreadyAdded = isAdded(tokenItem)

        if alreadyAdded {
            if selected {
                pendingRemove.remove(tokenItem)
            } else {
                pendingRemove.append(tokenItem)
            }
        } else {
            if selected {
                pendingAdd.append(tokenItem)
            } else {
                pendingAdd.remove(tokenItem)
            }
        }
        isPendingListsEmptySubject.send(pendingAdd.isEmpty && pendingRemove.isEmpty)
    }

    func updateSelection(_ tokenItem: TokenItem) {
        for item in listItemsViewModelsSubject.value {
            for itemItem in item.items {
                if itemItem.tokenItem == tokenItem {
                    itemItem.updateSelection(with: bindSelection(tokenItem))
                }
            }
        }
    }

    func showWarningDeleteAlertIfNeeded(isSelected: Bool, tokenItem: TokenItem) {
        guard !isSelected, userTokensManager.contains(tokenItem) else {
            onSelect(isSelected, tokenItem)
            return
        }

        let alertBuilder = HideTokenAlertBuilder()
        if canRemove(tokenItem) {
            alertSubject.send(alertBuilder.hideTokenAlert(
                tokenItem: tokenItem,
                hideAction: { [weak self] in
                    self?.onSelect(isSelected, tokenItem)
                },
                cancelAction: { [weak self] in
                    self?.updateSelection(tokenItem)
                }
            ))
        } else {
            alertSubject.send(alertBuilder.unableToHideTokenAlert(
                tokenItem: tokenItem, cancelAction: { [weak self] in
                    self?.updateSelection(tokenItem)
                }
            ))
        }
    }

    func bindSelection(_ tokenItem: TokenItem) -> Binding<Bool> {
        let binding = Binding<Bool> { [weak self] in
            self?.isSelected(tokenItem) ?? false
        } set: { [weak self] isSelected in
            self?.showWarningDeleteAlertIfNeeded(isSelected: isSelected, tokenItem: tokenItem)
        }

        return binding
    }

    func bindExpanded(_ coinId: String) -> Binding<Bool> {
        let binding = Binding<Bool> { [weak self] in
            self?.expandedCoinIds.contains(coinId) ?? false
        } set: { [weak self] isExpanded in
            self?.updateExpanded(state: isExpanded, for: coinId)
        }

        return binding
    }

    func bindCopy() -> Binding<Bool> {
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

    func mapToListItemViewModel(coinModel: CoinModel) -> ManageTokensListItemViewModel {
        let networkItems = coinModel.items.enumerated().map { index, item in
            ManageTokensItemNetworkSelectorViewModel(
                tokenItem: item.tokenItem,
                isReadonly: false,
                isSelected: bindSelection(item.tokenItem),
                isCopied: bindCopy(),
                position: .init(with: index, total: coinModel.items.count)
            )
        }

        return ManageTokensListItemViewModel(with: coinModel, items: networkItems)
    }

    func displayAlertAndUpdateSelection(for tokenItem: TokenItem, title: String, message: String) {
        let okButton = Alert.Button.default(Text(Localization.commonOk)) {
            self.updateSelection(tokenItem)
        }

        alertSubject.send(AlertBinder(
            alert: Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: okButton
            )
        ))
    }

    private func updateExpanded(state isExapanded: Bool, for coinId: String) {
        if isExapanded {
            expandedCoinIds.insert(coinId)
        } else {
            expandedCoinIds.remove(coinId)
        }
    }
}

// MARK: - Analytics

private extension ManageTokensAdapter {
    func sendAnalyticsOnChangeTokenState(tokenIsSelected: Bool, tokenItem: TokenItem) {
        let analyticsParams: [Analytics.ParameterKey: String] = [
            .state: Analytics.ParameterValue.toggleState(for: tokenIsSelected).rawValue,
            .token: tokenItem.currencySymbol,
            .source: analyticsSourceRawValue,
        ]

        Analytics.log(event: .manageTokensSwitcherChanged, params: analyticsParams)
    }

    /// Send analytics event for empty search tokens
    func sendIfNeededEmptySearchValueAnalyticsEvent() {
        guard let searchValue = loader.lastSearchTextValue, !searchValue.isEmpty, loader.items.isEmpty else {
            return
        }

        let analyticsParams: [Analytics.ParameterKey: String] = [.input: searchValue]
        Analytics.log(event: .manageTokensTokenIsNotFound, params: analyticsParams)
    }
}

extension ManageTokensAdapter {
    struct Settings {
        let longHashesSupported: Bool
        let existingCurves: [EllipticCurve]
        let supportedBlockchains: Set<Blockchain>
        let userTokensManager: UserTokensManager
        let analyticsSourceRawValue: String
    }
}
