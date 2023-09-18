//
//  WelcomeTokenListViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 18.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class WelcomeTokenListViewModel: ObservableObject {
    // I can't use @Published here, because of swiftui redraw perfomance drop
    var enteredSearchText = CurrentValueSubject<String, Never>("")

    @Published var coinViewModels: [LegacyCoinViewModel] = []

    @Published var isSaving: Bool = false
    @Published var isLoading: Bool = true

    var titleKey: String {
        return Localization.commonSearchTokens
    }

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    private lazy var loader = setupListDataLoader()
    private var bag = Set<AnyCancellable>()

    private unowned let coordinator: WelcomeTokenListRoutable

    init(coordinator: WelcomeTokenListRoutable) {
        self.coordinator = coordinator

        bind()
    }

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

// MARK: - Navigation

extension WelcomeTokenListViewModel {
    func closeModule() {
        coordinator.closeModule()
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
            .map { [weak self] items -> [LegacyCoinViewModel] in
                items.compactMap { self?.mapToCoinViewModel(coinModel: $0) }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.coinViewModels, on: self, ownership: .weak)
            .store(in: &bag)

        return loader
    }

    func mapToCoinViewModel(coinModel: CoinModel) -> LegacyCoinViewModel {
        let currencyItems = coinModel.items.enumerated().map { index, item in
            LegacyCoinItemViewModel(
                tokenItem: item,
                isReadonly: true,
                isSelected: nil,
                isCopied: .constant(false),
                position: .init(with: index, total: coinModel.items.count)
            )
        }

        return LegacyCoinViewModel(with: coinModel, items: currencyItems)
    }

    func isTokenAvailable(_ tokenItem: TokenItem) -> Bool {
        return true
    }
}
