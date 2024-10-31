//
//  CurrencySelectViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 09.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CurrencySelectViewModel: ObservableObject {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var state: LoadingValue<[CurrenciesResponse.Currency]> = .loading

    private weak var coordinator: CurrencySelectRoutable?
    private var loadCurrenciesCancellable: AnyCancellable?

    init(coordinator: CurrencySelectRoutable) {
        self.coordinator = coordinator
    }

    func onAppear() {
        state = .loading

        loadCurrenciesCancellable = tangemApiService
            .loadCurrencies()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.state = .failedToLoad(error: error)
                }
            }, receiveValue: { [weak self] currencies in
                let currencies = currencies.sorted { $0.description < $1.description }
                self?.state = .loaded(currencies)
            })
    }

    func isSelected(_ currency: CurrenciesResponse.Currency) -> Bool {
        AppSettings.shared.selectedCurrencyCode == currency.code
    }

    func onSelect(_ currency: CurrenciesResponse.Currency) {
        Analytics.log(event: .mainCurrencyChanged, params: [.currency: currency.description])
        objectWillChange.send()
        AppSettings.shared.selectedCurrencyCode = currency.code
        coordinator?.dismissCurrencySelect()
    }
}
