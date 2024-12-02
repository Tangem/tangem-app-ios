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
    private let formatter: SendCryptoValueFormatter

    private var bag: Set<AnyCancellable> = []

    init(onrampAmountInput: OnrampAmountInput, onrampProvidersInput: OnrampProvidersInput, tokenItem: TokenItem) {
        self.tokenItem = tokenItem

        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: 2)
        formatter = SendCryptoValueFormatter(
            decimals: tokenItem.decimalCount,
            currencySymbol: tokenItem.currencySymbol,
            trimFractions: false
        )

        bind(onrampAmountInput: onrampAmountInput, onrampProvidersInput: onrampProvidersInput)
    }
}

// MARK: - Private

private extension OnrampAmountCompactViewModel {
    private func bind(onrampAmountInput: OnrampAmountInput, onrampProvidersInput: OnrampProvidersInput) {
        onrampAmountInput
            .amountPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amount in
                viewModel.decimalNumberTextFieldViewModel.update(value: amount)
            }
            .store(in: &bag)

        onrampAmountInput
            .fiatCurrencyPublisher
            .compactMap { $0.value }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, currency in
                viewModel.update(currency: currency)
            }
            .store(in: &bag)

        onrampProvidersInput
            .selectedOnrampProviderPublisher
            .compactMap { $0?.value }
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

    func update(provider: OnrampProvider) {
        providerName = provider.provider.name
        providerIconURL = provider.provider.imageURL

        let amount = provider.quote?.expectedAmount
        let formatted = amount.flatMap { formatter.string(from: $0) }
        alternativeAmount = formatted.map { "\(AppConstants.tildeSign) \($0)" }
    }
}
