//
//  WelcomeSearchTokensViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 22/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class WelcomeSearchTokensViewModel: Identifiable, ObservableObject {
    // I can't use @Published here, because of swiftui redraw perfomance drop
    var enteredSearchText = CurrentValueSubject<String, Never>("")
    var manageTokensListViewModel: ManageTokensListViewModel!

    @Published var coinViewModels: [ManageTokensCoinViewModel] = []
    @Published var isLoading: Bool = true

    private lazy var loader = setupListDataLoader()
    private var bag = Set<AnyCancellable>()

    init() {
        manageTokensListViewModel = .init(
            loader: self,
            coinViewModelsPublisher: $coinViewModels
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

                self?.loader.fetch(string)
            }
            .store(in: &bag)
    }

    func setupListDataLoader() -> ListDataLoader {
        let supportedBlockchains = SupportedBlockchains.all
        let loader = ListDataLoader(supportedBlockchains: supportedBlockchains)

        loader.$items
            .withWeakCaptureOf(self)
            .map { viewModel, items -> [ManageTokensCoinViewModel] in
                items.compactMap(viewModel.mapToCoinViewModel(coinModel:))
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.coinViewModels, on: self, ownership: .weak)
            .store(in: &bag)

        return loader
    }

    func mapToCoinViewModel(coinModel: CoinModel) -> ManageTokensCoinViewModel {
        let currencyItems = coinModel.items.enumerated().map { index, item in
            ManageTokensCoinItemViewModel(
                tokenItem: item.tokenItem,
                isReadonly: true,
                isSelected: .constant(false),
                isCopied: .constant(false),
                position: .init(with: index, total: coinModel.items.count)
            )
        }

        return ManageTokensCoinViewModel(with: coinModel, items: currencyItems)
    }
}
