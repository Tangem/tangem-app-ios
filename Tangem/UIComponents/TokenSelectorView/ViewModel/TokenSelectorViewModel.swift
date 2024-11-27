//
//  TokenSelectorViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class TokenSelectorViewModel<
    TokenModel: Identifiable & Equatable,
    Builder: TokenSelectorItemBuilder
>: ObservableObject where Builder.TokenModel == TokenModel {
    @Published var searchText: String = ""

    @Published private(set) var viewState: ViewState = .empty

    var isAvailableItemsBlockVisible: Bool {
        guard
            case .data(let availableItems, let unavailableItems) = viewState,
            (availableItems.isEmpty && unavailableItems.isEmpty) || availableItems.isNotEmpty
        else {
            return false
        }

        return true
    }

    let strings: TokenSelectorLocalizable

    private var availableWalletModels: [WalletModel] = []
    private var unavailableWalletModels: [WalletModel] = []
    private var bag: Set<AnyCancellable> = []

    private let tokenSelectorItemBuilder: Builder
    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let tokenSorter: TokenAvailabilitySorter

    init(
        tokenSelectorItemBuilder: Builder,
        strings: some TokenSelectorLocalizable,
        expressTokensListAdapter: some ExpressTokensListAdapter,
        tokenSorter: some TokenAvailabilitySorter
    ) {
        self.tokenSelectorItemBuilder = tokenSelectorItemBuilder
        self.strings = strings
        self.expressTokensListAdapter = expressTokensListAdapter
        self.tokenSorter = tokenSorter

        bind()
    }

    func bind() {
        bindWalletModels()
        bindSearchText()
    }

    private func bindWalletModels() {
        expressTokensListAdapter
            .walletModels()
            .asyncMap { walletModels in
                await self.tokenSorter.sortModels(walletModels: walletModels)
            }
            .withWeakCaptureOf(self)
            .sink { viewModel, sortedWalletModels in
                viewModel.availableWalletModels = sortedWalletModels.availableModels
                viewModel.unavailableWalletModels = sortedWalletModels.unavailableModels

                viewModel.updateView(
                    availableModels: sortedWalletModels.availableModels,
                    unavailableModels: sortedWalletModels.unavailableModels
                )
            }
            .store(in: &bag)
    }

    private func updateView(availableModels: [WalletModel], unavailableModels: [WalletModel]) {
        let availableTokenItems = availableModels.map { tokenSelectorItemBuilder.map(from: $0, isDisabled: false) }
        let unavailableTokenItems = unavailableModels.map { tokenSelectorItemBuilder.map(from: $0, isDisabled: true) }

        Task { @MainActor [weak self] in
            if availableTokenItems.isNotEmpty || unavailableTokenItems.isNotEmpty {
                self?.viewState = .data(availableTokens: availableTokenItems, unavailableTokens: unavailableTokenItems)
            } else {
                self?.viewState = .empty
            }
        }
    }
}

// MARK: - Search

private extension TokenSelectorViewModel {
    func bindSearchText() {
        $searchText
            .removeDuplicates()
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { viewModel, searchText in
                viewModel.updateView(searchText: searchText.trimmed())
            }
            .store(in: &bag)
    }

    func updateView(searchText: String = "") {
        let availableTokenItems = availableWalletModels
            .filter { filter(searchText, item: $0.tokenItem) }
            .map { tokenSelectorItemBuilder.map(from: $0, isDisabled: false) }

        let unavailableTokenItems = unavailableWalletModels
            .filter { filter(searchText, item: $0.tokenItem) }
            .map { tokenSelectorItemBuilder.map(from: $0, isDisabled: true) }

        viewState = .data(availableTokens: availableTokenItems, unavailableTokens: unavailableTokenItems)
    }

    func filter(_ text: String, item: TokenItem) -> Bool {
        if text.isEmpty {
            return true
        }

        let isContainsName = item.name.caseInsensitiveContains(text)
        let isContainsCurrencySymbol = item.currencySymbol.caseInsensitiveContains(text)

        return isContainsName || isContainsCurrencySymbol
    }
}

// MARK: - View state

extension TokenSelectorViewModel {
    enum ViewState: Equatable {
        case empty
        case data(availableTokens: [TokenModel], unavailableTokens: [TokenModel])
    }
}
