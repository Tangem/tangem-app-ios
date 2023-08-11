//
//  LegacyTokenListViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 09/02/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemSdk
import SwiftUI

class LegacyTokenListViewModel: ObservableObject {
    // I can't use @Published here, because of swiftui redraw perfomance drop
    var enteredSearchText = CurrentValueSubject<String, Never>("")

    @Published var coinViewModels: [LegacyCoinViewModel] = []

    @Published var isSaving: Bool = false
    @Published var isLoading: Bool = true
    @Published var alert: AlertBinder?
    @Published var pendingAdd: [TokenItem] = []
    @Published var pendingRemove: [TokenItem] = []
    @Published var showToast: Bool = false

    var titleKey: String {
        switch mode {
        case .add:
            return Localization.addTokensTitle
        case .show:
            return Localization.commonSearchTokens
        }
    }

    var isReadonlyMode: Bool {
        switch mode {
        case .add:
            return false
        case .show:
            return true
        }
    }

    var shouldShowAlert: Bool {
        mode.settings?.shouldShowLegacyDerivationAlert ?? false
    }

    var isSaveDisabled: Bool {
        pendingAdd.isEmpty && pendingRemove.isEmpty
    }

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    private lazy var loader = setupListDataLoader()
    private let mode: Mode
    private var bag = Set<AnyCancellable>()
    private unowned let coordinator: LegacyTokenListRoutable

    init(mode: Mode, coordinator: LegacyTokenListRoutable) {
        self.mode = mode
        self.coordinator = coordinator

        bind()
    }

    func saveChanges() {
        guard let userTokensManager = mode.userTokensManager else {
            closeModule()
            return
        }

        isSaving = true

        userTokensManager.update(
            itemsToRemove: pendingRemove,
            itemsToAdd: pendingAdd,
            derivationPath: nil
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSaving = false

                switch result {
                case .success:
                    self?.tokenListDidSave()
                case .failure(let error):
                    if error.isUserCancelled {
                        return
                    }

                    self?.alert = error.alertBinder
                }
            }
        }
    }

    func tokenListDidSave() {
        Analytics.log(.buttonSaveChanges)
        closeModule()
    }

    func onAppear() {
        if !isReadonlyMode {
            Analytics.log(.manageTokensScreenOpened)
        }

        loader.reset(enteredSearchText.value)
    }

    func onDisappear() {
        DispatchQueue.main.async {
            self.pendingAdd = []
            self.pendingRemove = []
            self.enteredSearchText.value = ""
        }
    }

    func fetch() {
        loader.fetch(enteredSearchText.value)
    }
}

// MARK: - Navigation

extension LegacyTokenListViewModel {
    func closeModule() {
        coordinator.closeModule()
    }

    func openAddCustom() {
        if let settings = mode.settings, let userTokensManager = mode.userTokensManager {
            Analytics.log(.buttonCustomToken)
            coordinator.openAddCustom(settings: settings, userTokensManager: userTokensManager)
        }
    }
}

// MARK: - Private

private extension LegacyTokenListViewModel {
    func bind() {
        enteredSearchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] string in
                if !string.isEmpty {
                    Analytics.log(.tokenSearched)
                }

                self?.loader.fetch(string)
            }
            .store(in: &bag)
    }

    func showAddButton(_ tokenItem: TokenItem) -> Bool {
        switch mode {
        case .add:
            return true
        case .show:
            return false
        }
    }

    func setupListDataLoader() -> ListDataLoader {
        let supportedBlockchains = mode.settings?.supportedBlockchains ?? SupportedBlockchains.all
        let loader = ListDataLoader(supportedBlockchains: supportedBlockchains)

        loader.$items
            .map { [weak self] items -> [LegacyCoinViewModel] in
                items.compactMap { self?.mapToCoinViewModel(coinModel: $0) }
            }
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.coinViewModels, on: self)
            .store(in: &bag)

        return loader
    }

    func isAdded(_ tokenItem: TokenItem) -> Bool {
        guard let userTokensManager = mode.userTokensManager else {
            return false
        }

        return userTokensManager.contains(tokenItem, derivationPath: nil)
    }

    func canRemove(_ tokenItem: TokenItem) -> Bool {
        guard let userTokensManager = mode.userTokensManager else {
            return false
        }

        return userTokensManager.canRemove(tokenItem, derivationPath: nil)
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
        guard let settings = mode.settings else {
            return
        }

        if selected,
           case .token(_, let blockchain) = tokenItem,
           case .solana = blockchain,
           !settings.longHashesSupported {
            let okButton = Alert.Button.default(Text(Localization.commonOk)) {
                self.updateSelection(tokenItem)
            }

            alert = AlertBinder(alert: Alert(
                title: Text(Localization.commonAttention),
                message: Text(Localization.alertManageTokensUnsupportedMessage),
                dismissButton: okButton
            ))

            return
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
    }

    func updateSelection(_ tokenItem: TokenItem) {
        for item in coinViewModels {
            for itemItem in item.items {
                if itemItem.tokenItem == tokenItem {
                    itemItem.updateSelection(with: bindSelection(tokenItem))
                }
            }
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
        let binding = Binding<Bool> { [weak self] in
            self?.showToast ?? false
        } set: { [weak self] isSelected in
            self?.showToast = isSelected
        }

        return binding
    }

    func mapToCoinViewModel(coinModel: CoinModel) -> LegacyCoinViewModel {
        let currencyItems = coinModel.items.enumerated().map { index, item in
            LegacyCoinItemViewModel(
                tokenItem: item,
                isReadonly: isReadonlyMode,
                isSelected: bindSelection(item),
                isCopied: bindCopy(),
                position: .init(with: index, total: coinModel.items.count)
            )
        }

        return LegacyCoinViewModel(with: coinModel, items: currencyItems)
    }

    func showWarningDeleteAlertIfNeeded(isSelected: Bool, tokenItem: TokenItem) {
        guard !isSelected,
              !pendingAdd.contains(tokenItem),
              isTokenAvailable(tokenItem) else {
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

            alert = AlertBinder(alert:
                Alert(
                    title: Text(title),
                    message: Text(Localization.tokenDetailsHideAlertMessage),
                    primaryButton: .destructive(Text(Localization.tokenDetailsHideAlertHide), action: hideAction),
                    secondaryButton: .cancel(cancelAction)
                )
            )
        } else {
            let title = Localization.tokenDetailsUnableHideAlertTitle(tokenItem.blockchain.currencySymbol)

            let message = Localization.tokenDetailsUnableHideAlertMessage(
                tokenItem.blockchain.currencySymbol,
                tokenItem.blockchain.displayName
            )

            alert = AlertBinder(alert: Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: .default(Text(Localization.commonOk), action: {
                    self.updateSelection(tokenItem)
                })
            ))
        }
    }

    func isTokenAvailable(_ tokenItem: TokenItem) -> Bool {
        if case .token(_, let blockchain) = tokenItem,
           case .solana = blockchain,
           mode.settings?.longHashesSupported == false {
            return false
        }
        return true
    }

    func sendAnalyticsOnChangeTokenState(tokenIsSelected: Bool, tokenItem: TokenItem) {
        Analytics.log(event: .tokenSwitcherChanged, params: [
            .state: Analytics.ParameterValue.state(for: tokenIsSelected).rawValue,
            .token: tokenItem.currencySymbol,
        ])
    }
}

// TODO: refactor, split into separate viewModels
extension LegacyTokenListViewModel {
    enum Mode {
        case add(
            settings: LegacyManageTokensSettings,
            userTokensManager: UserTokensManager
        )
        case show

        fileprivate var settings: LegacyManageTokensSettings? {
            switch self {
            case .add(let settings, _):
                return settings
            case .show:
                return nil
            }
        }

        fileprivate var userTokensManager: UserTokensManager? {
            switch self {
            case .add(_, let userTokensManager):
                return userTokensManager
            case .show:
                return nil
            }
        }
    }
}
