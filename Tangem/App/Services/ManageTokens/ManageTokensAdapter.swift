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
    private let loader: ListDataLoader

    private let coinViewModelsSubject = CurrentValueSubject<[ManageTokensCoinViewModel], Never>([])
    private let alertSubject = CurrentValueSubject<AlertBinder?, Never>(nil)
    private let isPendingListsEmptySubject = CurrentValueSubject<Bool, Never>(true)

    private var pendingAdd: [TokenItem] = []
    private var pendingRemove: [TokenItem] = []

    private var bag = Set<AnyCancellable>()

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    var coinViewModelsPublisher: some Publisher<[ManageTokensCoinViewModel], Never> {
        coinViewModelsSubject
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
        loader = ListDataLoader(supportedBlockchains: settings.supportedBlockchains)

        bind()
    }

    func saveChanges(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        userTokensManager.update(itemsToRemove: pendingRemove, itemsToAdd: pendingAdd, completion: completion)
    }

    func resetAdapter() {
        pendingAdd = []
        pendingRemove = []
        isPendingListsEmptySubject.send(true)
    }

    func fetch(_ text: String) {
        loader.fetch(text)
    }
}

private extension ManageTokensAdapter {
    func bind() {
        loader.$items
            .withWeakCaptureOf(self)
            .map { adapter, items -> [ManageTokensCoinViewModel] in
                items.compactMap(adapter.mapToCoinViewModel(coinModel:))
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.value, on: coinViewModelsSubject, ownership: .weak)
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
        for item in coinViewModelsSubject.value {
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

        if canRemove(tokenItem) {
            let title = Localization.tokenDetailsHideAlertTitle(tokenItem.currencySymbol)

            let cancelAction = { [unowned self] in
                updateSelection(tokenItem)
            }

            let hideAction = { [unowned self] in
                onSelect(isSelected, tokenItem)
            }

            alertSubject.send(AlertBinder(
                alert: Alert(
                    title: Text(title),
                    message: Text(Localization.tokenDetailsHideAlertMessage),
                    primaryButton: .destructive(Text(Localization.tokenDetailsHideAlertHide), action: hideAction),
                    secondaryButton: .cancel(cancelAction)
                )
            ))
        } else {
            let title = Localization.tokenDetailsUnableHideAlertTitle(tokenItem.blockchain.currencySymbol)

            let message = Localization.tokenDetailsUnableHideAlertMessage(
                tokenItem.name,
                tokenItem.blockchain.currencySymbol,
                tokenItem.blockchain.displayName
            )

            alertSubject.send(AlertBinder(
                alert: Alert(
                    title: Text(title),
                    message: Text(message),
                    dismissButton: .default(Text(Localization.commonOk), action: {
                        self.updateSelection(tokenItem)
                    })
                )
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

    func mapToCoinViewModel(coinModel: CoinModel) -> ManageTokensCoinViewModel {
        let currencyItems = coinModel.items.enumerated().map { index, item in
            ManageTokensCoinItemViewModel(
                tokenItem: item.tokenItem,
                isReadonly: false,
                isSelected: bindSelection(item.tokenItem),
                isCopied: bindCopy(),
                position: .init(with: index, total: coinModel.items.count)
            )
        }

        return ManageTokensCoinViewModel(with: coinModel, items: currencyItems)
    }

    func sendAnalyticsOnChangeTokenState(tokenIsSelected: Bool, tokenItem: TokenItem) {
        Analytics.log(event: .manageTokensSwitcherChanged, params: [
            .state: Analytics.ParameterValue.toggleState(for: tokenIsSelected).rawValue,
            .token: tokenItem.currencySymbol,
        ])
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
}

extension ManageTokensAdapter {
    struct Settings {
        let longHashesSupported: Bool
        let existingCurves: [EllipticCurve]
        let supportedBlockchains: Set<Blockchain>
        let userTokensManager: UserTokensManager
    }
}
