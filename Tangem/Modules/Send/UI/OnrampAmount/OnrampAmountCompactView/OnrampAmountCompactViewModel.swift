//
//  OnrampAmountCompactViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 13.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation

class OnrampAmountCompactViewModel: ObservableObject {
    @Published var fiatIconURL: URL?
    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions?
    @Published var alternativeAmount: String?
    @Published var providerName: String?
    @Published var providerIconURL: URL?

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory = .init()

    private var bag: Set<AnyCancellable> = []

    init(onrampAmountInput: OnrampAmountInput, onrampProvidersInput: OnrampProvidersInput, tokenItem: TokenItem) {
        self.tokenItem = tokenItem

        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: 2)

        bind(onrampAmountInput: onrampAmountInput, onrampProvidersInput: onrampProvidersInput)
    }
}

// MARK: - Private

private extension OnrampAmountCompactViewModel {
    private func bind(onrampAmountInput: OnrampAmountInput, onrampProvidersInput: OnrampProvidersInput) {
        onrampAmountInput
            .fiatCurrencyPublisher
            .compactMap { $0.value }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, currency in
                viewModel.update(currency: currency)
            }
            .store(in: &bag)

        onrampAmountInput
            .amountPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amount in
                viewModel.update(amount: amount)
            }
            .store(in: &bag)

        onrampProvidersInput
            .selectedOnrampProviderPublisher
            .compactMap { $0?.value?.provider }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, provider in
                viewModel.update(provider: provider)
            }
            .store(in: &bag)
    }

    func update(currency: OnrampFiatCurrency) {
        fiatIconURL = currency.identity.image
        decimalNumberTextFieldViewModel.update(maximumFractionDigits: currency.precision)
        currentFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(
            fiatCurrencyCode: currency.identity.code
        )
    }

    func update(amount: SendAmount?) {
        let amount = amount ?? SendAmount(type: .alternative(fiat: nil, crypto: 0))

        decimalNumberTextFieldViewModel.update(value: amount.main)
        alternativeAmount = amount.formatAlternative(
            currencySymbol: tokenItem.currencySymbol,
            trimFractions: false,
            decimalCount: tokenItem.decimalCount
        )
    }

    func update(provider: ExpressProvider) {
        providerName = provider.name
        providerIconURL = provider.imageURL
    }
}
