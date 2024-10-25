//
//  OnrampInteractor.swift
//  TangemApp
//
//  Created by Sergey Balashov on 18.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampInteractor: AnyObject {
    var isValidPublisher: AnyPublisher<Bool, Never> { get }
    var selectedQuotePublisher: AnyPublisher<LoadingValue<OnrampQuote>?, Never> { get }
}

class CommonOnrampInteractor {
    private weak var input: OnrampInput?
    private weak var output: OnrampOutput?

    private let _isValid: CurrentValueSubject<Bool, Never> = .init(true)

    init(input: OnrampInput, output: OnrampOutput) {
        self.input = input
        self.output = output

        bind()
    }

    private func bind() {}
}

// MARK: - OnrampInteractor

extension CommonOnrampInteractor: OnrampInteractor {
    var isValidPublisher: AnyPublisher<Bool, Never> {
        _isValid.eraseToAnyPublisher()
    }

    var selectedQuotePublisher: AnyPublisher<LoadingValue<OnrampQuote>?, Never> {
        guard let input else {
            return Empty().eraseToAnyPublisher()
        }

        return Publishers.CombineLatest(
            input.isLoadingRatesPublisher,
            input.selectedQuotePublisher
        )
        .map { isLoadingRates, selectedQuote in
            if isLoadingRates {
                return .loading
            }

            if let selectedQuote {
                return .loaded(selectedQuote)
            }

            return nil
        }
        .eraseToAnyPublisher()
    }
}
