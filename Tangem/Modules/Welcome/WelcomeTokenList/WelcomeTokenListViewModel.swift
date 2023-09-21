//
//  WelcomeTokenListViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 18.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class WelcomeTokenListViewModel: ObservableObject, Identifiable {
    // I can't use @Published here, because of swiftui redraw perfomance drop
    var enteredSearchText = CurrentValueSubject<String, Never>("")

    @Published var itemViewModels: [WelcomeTokenListSectionViewModel] = []

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    private lazy var loader = setupListDataLoader()
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        bind()
    }

    // MARK: - Implementation

    func onAppear() {
        loader.reset(enteredSearchText.value)
    }

    func onDisappear() {
        DispatchQueue.main.async {
            self.enteredSearchText.value = ""
        }
    }

    func fetch() {
        loader.fetch(enteredSearchText.value)
    }
}

// MARK: - Private

private extension WelcomeTokenListViewModel {
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

    func setupListDataLoader() -> ListDataLoader {
        let supportedBlockchains = SupportedBlockchains.all
        let loader = ListDataLoader(supportedBlockchains: supportedBlockchains)

        loader.$items
            .map { [weak self] items -> [WelcomeTokenListSectionViewModel] in
                items.compactMap { self?.mapToCoinViewModel(coinModel: $0) }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.itemViewModels, on: self, ownership: .weak)
            .store(in: &bag)

        return loader
    }

    func mapToCoinViewModel(coinModel: CoinModel) -> WelcomeTokenListSectionViewModel {
        let items = coinModel.items.enumerated().map { index, item in
            WelcomeTokenListItemViewModel(
                tokenItem: item,
                isSelected: nil,
                position: .init(with: index, total: coinModel.items.count)
            )
        }

        return WelcomeTokenListSectionViewModel(with: coinModel, items: items)
    }
}
