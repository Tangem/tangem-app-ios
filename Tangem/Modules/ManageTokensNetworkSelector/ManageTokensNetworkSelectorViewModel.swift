//
//  ManageTokensNetworkSelectorViewModel.swift
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

final class ManageTokensNetworkSelectorViewModel: Identifiable, ObservableObject, WalletSelectorDelegate {
    // MARK: - Injected Properties

    @Injected(\.quotesRepository) private var tokenQuotesRepository: TokenQuotesRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Published Properties

    @Published var currentWalletName: String = ""

    @Published var nativeSelectorItems: [ManageTokensNetworkSelectorItemViewModel] = []
    @Published var nonNativeSelectorItems: [ManageTokensNetworkSelectorItemViewModel] = []

    @Published var alert: AlertBinder?
    @Published var pendingAdd: [TokenItem] = []
    @Published var pendingRemove: [TokenItem] = []

    var isSaveDisabled: Bool {
        pendingAdd.isEmpty && pendingRemove.isEmpty
    }

    // MARK: - Private Implementation

    private let alertBuilder = ManageTokensNetworkSelectorAlertBuilder()
    private var tokenItems: [TokenItem]

    private var userTokensManager: UserTokensManager? {
        userWalletRepository.selectedModel?.userTokensManager
    }

    private var settings: Settings {
        let selectedModel = userWalletRepository.selectedModel

        return .init(
            supportedBlockchains: selectedModel?.config.supportedBlockchains ?? [],
            hdWalletsSupported: selectedModel?.userWallet.isHDWalletAllowed ?? false,
            longHashesSupported: selectedModel?.longHashesSupported ?? false,
            derivationStyle: nil,
            shouldShowLegacyDerivationAlert: selectedModel?.shouldShowLegacyDerivationAlert ?? false,
            existingCurves: selectedModel?.card.walletCurves ?? []
        )
    }

    // MARK: - Private Properties

    private unowned let coordinator: ManageTokensNetworkSelectorCoordinator

    // MARK: - Init

    init(tokenItems: [TokenItem], coordinator: ManageTokensNetworkSelectorCoordinator) {
        self.coordinator = coordinator
        self.tokenItems = tokenItems

        fillSelectorItemsFromTokenItems()
    }

    // MARK: - Implementation

    func onAppear() {
        currentWalletName = userWalletRepository.selectedModel?.name ?? ""
    }

    func onDisappear() {
        saveChanges()
    }

    func selectWalletActionDidTap() {
        coordinator.openWalletSelectorModule(
            userWallets: userWalletRepository.userWallets,
            currentUserWalletId: userWalletRepository.selectedUserWalletId,
            delegate: self
        )
    }

    // MARK: - Private Implementation

    private func fillSelectorItemsFromTokenItems() {
        nativeSelectorItems = tokenItems
            .filter {
                $0.isBlockchain
            }
            .map {
                .init(
                    id: $0.hashValue,
                    isMain: $0.isBlockchain,
                    iconName: $0.blockchain.iconName,
                    iconNameSelected: $0.blockchain.iconNameFilled,
                    networkName: $0.networkName,
                    tokenTypeName: nil,
                    isSelected: bindSelection($0)
                )
            }

        nonNativeSelectorItems = tokenItems
            .filter {
                $0.isToken
            }
            .map {
                .init(
                    id: $0.hashValue,
                    isMain: $0.isBlockchain,
                    iconName: $0.blockchain.iconName,
                    iconNameSelected: $0.blockchain.iconNameFilled,
                    networkName: $0.networkName,
                    tokenTypeName: $0.blockchain.tokenTypeName,
                    isSelected: bindSelection($0)
                )
            }
    }

    private func saveChanges() {
        guard let userTokensManager = userTokensManager else {
            return
        }

        userTokensManager.update(
            itemsToRemove: pendingRemove,
            itemsToAdd: pendingAdd,
            derivationPath: nil
        )
    }

    private func onSelect(_ selected: Bool, _ tokenItem: TokenItem) throws {
        if selected {
            try tryTokenAvailable(tokenItem)
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

    private func bindSelection(_ tokenItem: TokenItem) -> Binding<Bool> {
        let binding = Binding<Bool> { [weak self] in
            self?.isSelected(tokenItem) ?? false
        } set: { [weak self] isSelected in
            do {
                try self?.displayAlertWarningDeleteIfNeeded(isSelected: isSelected, tokenItem: tokenItem)
            } catch {
                self?.displayAlertAndUpdateSelection(for: tokenItem, error: error)
            }
        }

        return binding
    }

    private func updateSelection(_ tokenItem: TokenItem) {
        if tokenItem.isBlockchain {
            nativeSelectorItems
                .first(where: { $0.id == tokenItem.hashValue })?
                .updateSelection(with: bindSelection(tokenItem))
        } else {
            nonNativeSelectorItems
                .first(where: { $0.id == tokenItem.hashValue })?
                .updateSelection(with: bindSelection(tokenItem))
        }
    }

    private func sendAnalyticsOnChangeTokenState(tokenIsSelected: Bool, tokenItem: TokenItem) {
        Analytics.log(event: .tokenSwitcherChanged, params: [
            .state: Analytics.ParameterValue.toggleState(for: tokenIsSelected).rawValue,
            .token: tokenItem.currencySymbol,
        ])
    }

    // MARK: - ManageTokensNetworkSelectorViewModel

    func didSelectWallet(with userWalletId: Data) {
        pendingAdd = []
        pendingRemove = []

        userWalletRepository.setSelectedUserWalletId(userWalletId, reason: .userSelected)
        fillSelectorItemsFromTokenItems()
    }
}

// MARK: - Helpers

private extension ManageTokensNetworkSelectorViewModel {
    func tryTokenAvailable(_ tokenItem: TokenItem) throws {
        guard settings.supportedBlockchains.contains(tokenItem.blockchain) else {
            throw AvailableTokenError.failedSupportedBlockchainByCard(tokenItem)
        }

        guard settings.existingCurves.contains(tokenItem.blockchain.curve) else {
            throw AvailableTokenError.failedSupportedCurve(tokenItem)
        }

        if settings.longHashesSupported, !tokenItem.blockchain.hasLongTransactions {
            throw AvailableTokenError.failedSupportedLongHahesTokens(tokenItem)
        }

        return
    }

    func isTokenAvailable(_ tokenItem: TokenItem) -> Bool {
        return (try? tryTokenAvailable(tokenItem)) != nil
    }

    private func isAdded(_ tokenItem: TokenItem) -> Bool {
        userTokensManager?.contains(tokenItem, derivationPath: nil) ?? false
    }

    private func canRemove(_ tokenItem: TokenItem) -> Bool {
        userTokensManager?.canRemove(tokenItem, derivationPath: nil) ?? false
    }

    private func isSelected(_ tokenItem: TokenItem) -> Bool {
        let isWaitingToBeAdded = pendingAdd.contains(tokenItem)
        let isWaitingToBeRemoved = pendingRemove.contains(tokenItem)
        let alreadyAdded = isAdded(tokenItem)

        if isWaitingToBeRemoved {
            return false
        }

        return isWaitingToBeAdded || alreadyAdded
    }
}

// MARK: - Alerts

private extension ManageTokensNetworkSelectorViewModel {
    func displayAlertAndUpdateSelection(for tokenItem: TokenItem, error: Error) {
        guard let availableTokenError = error as? AvailableTokenError else {
            return
        }

        let okButton = Alert.Button.default(Text(Localization.commonOk)) {
            self.updateSelection(tokenItem)
        }

        alert = AlertBinder(alert: Alert(
            title: Text(availableTokenError.title),
            message: Text(availableTokenError.errorDescription ?? ""),
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

    func displayAlertWarningDeleteIfNeeded(isSelected: Bool, tokenItem: TokenItem) throws {
        guard
            !isSelected,
            !pendingAdd.contains(tokenItem),
            isTokenAvailable(tokenItem)
        else {
            try onSelect(isSelected, tokenItem)
            return
        }

        if canRemove(tokenItem) {
            alert = alertBuilder.successCanRemoveAlertDeleteTokenIfNeeded(
                tokenItem: tokenItem,
                cancelAction: { [unowned self] in
                    updateSelection(tokenItem)
                },
                hideAction: { [unowned self] in
                    do {
                        try onSelect(isSelected, tokenItem)
                    } catch {
                        displayAlertAndUpdateSelection(for: tokenItem, error: error)
                    }
                }
            )
        } else {
            alert = alertBuilder.errorCanRemoveAlertDeleteTokenIfNeeded(
                tokenItem: tokenItem,
                dissmisAction: { [unowned self] item in
                    updateSelection(item)
                }
            )
        }
    }
}

// MARK: - Settings

private extension ManageTokensNetworkSelectorViewModel {
    struct Settings {
        let supportedBlockchains: Set<Blockchain>
        let hdWalletsSupported: Bool
        let longHashesSupported: Bool
        let derivationStyle: DerivationStyle?
        let shouldShowLegacyDerivationAlert: Bool
        let existingCurves: [EllipticCurve]
    }
}

// MARK: - Errors

private extension ManageTokensNetworkSelectorViewModel {
    enum AvailableTokenError: Error, LocalizedError {
        case failedSupportedLongHahesTokens(TokenItem)
        case failedSupportedCurve(TokenItem)
        case failedSupportedBlockchainByCard(TokenItem)

        var errorDescription: String? {
            switch self {
            case .failedSupportedLongHahesTokens:
                return Localization.alertManageTokensUnsupportedMessage
            case .failedSupportedCurve(let tokenItem):
                return Localization.alertManageTokensUnsupportedCurveMessage(tokenItem.blockchain.displayName)
            case .failedSupportedBlockchainByCard:
                return nil
            }
        }

        var title: String {
            return Localization.commonAttention
        }
    }
}
