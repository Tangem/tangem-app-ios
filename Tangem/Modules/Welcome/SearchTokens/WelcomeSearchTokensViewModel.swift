//
//  WelcomeSearchTokensViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 22/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class WelcomeSearchTokensViewModel: Identifiable, ObservableObject {
    // I can't use @Published here, because of swiftui redraw perfomance drop
    var enteredSearchText = CurrentValueSubject<String, Never>("")
    var manageTokensListViewModel: ManageTokensListViewModel!

    @Published var listItemsViewModels: [ManageTokensListItemViewModel] = []
    @Published var isLoading: Bool = true

    private lazy var loader = setupListDataLoader()
    private var bag = Set<AnyCancellable>()

    private var expandedCoinIds: Set<String> = []

    init() {
        manageTokensListViewModel = .init(
            loader: self,
            listItemsViewModelsPublisher: $listItemsViewModels
        )

        bind()
    }

    func onAppear() {
        reset()
    }

    func onDisappear() {
        DispatchQueue.main.async {
            self.enteredSearchText.value = ""
        }
    }
}

extension WelcomeSearchTokensViewModel: ManageTokensListLoader {
    var hasNextPage: Bool {
        loader.canFetchMore
    }

    func fetch() {
        loader.fetch(enteredSearchText.value)
    }

    func reset() {
        expandedCoinIds.removeAll()
        loader.reset(enteredSearchText.value)
    }
}

// MARK: - Private

private extension WelcomeSearchTokensViewModel {
    func bind() {
        enteredSearchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] string in
                if !string.isEmpty {
                    Analytics.log(.manageTokensSearched)
                }

                self?.expandedCoinIds.removeAll()
                self?.loader.fetch(string)
            }
            .store(in: &bag)
    }

    func setupListDataLoader() -> TokensListDataLoader {
        let supportedBlockchains = SupportedBlockchains.all
        let loader = TokensListDataLoader(supportedBlockchains: supportedBlockchains)

        loader.$items
            .withWeakCaptureOf(self)
            .map { viewModel, items -> [ManageTokensListItemViewModel] in
                let viewModels = items.compactMap(viewModel.mapToCoinViewModel(coinModel:))
                viewModels.forEach { $0.update(expanded: viewModel.bindExpanded($0.coinId)) }
                return viewModels
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.listItemsViewModels, on: self, ownership: .weak)
            .store(in: &bag)

        return loader
    }

    func bindExpanded(_ coinId: String) -> Binding<Bool> {
        let binding = Binding<Bool> { [weak self] in
            self?.expandedCoinIds.contains(coinId) ?? false
        } set: { [weak self] isExpanded in
            self?.updateExpanded(state: isExpanded, for: coinId)
        }

        return binding
    }

    func mapToCoinViewModel(coinModel: CoinModel) -> ManageTokensListItemViewModel {
        let networkItems = coinModel.items.enumerated().map { index, item in
            ManageTokensItemNetworkSelectorViewModel(
                tokenItem: item.tokenItem,
                isReadonly: true,
                isSelected: .constant(false),
                isCopied: .constant(false),
                position: .init(with: index, total: coinModel.items.count)
            )
        }

        return ManageTokensListItemViewModel(with: coinModel, items: networkItems)
    }

    private func updateExpanded(state isExapanded: Bool, for coinId: String) {
        if isExapanded {
            expandedCoinIds.insert(coinId)
        } else {
            expandedCoinIds.remove(coinId)
        }
    }
}
