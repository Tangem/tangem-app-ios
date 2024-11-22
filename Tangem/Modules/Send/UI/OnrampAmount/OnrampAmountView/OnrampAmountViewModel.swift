//
//  OnrampAmountViewModel.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation

class OnrampAmountViewModel: ObservableObject {
    @Published var fiatIconURL: URL?
    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var alternativeAmount: LoadableTextView.State = .initialized
    @Published var bottomInfoText: SendAmountViewModel.BottomInfoTextType?
    @Published var currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions?
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let interactor: OnrampAmountInteractor
    private weak var coordinator: OnrampAmountRoutable?
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory = .init()
    private let formatter: SendCryptoValueFormatter

    private var bag: Set<AnyCancellable> = []

    init(
        tokenItem: TokenItem,
        interactor: OnrampAmountInteractor,
        coordinator: OnrampAmountRoutable
    ) {
        self.tokenItem = tokenItem
        self.interactor = interactor
        self.coordinator = coordinator

        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: 2)
        formatter = SendCryptoValueFormatter(
            decimals: tokenItem.decimalCount,
            currencySymbol: tokenItem.currencySymbol,
            trimFractions: false
        )

        bind()
    }

    func onChangeCurrencyTap() {
        coordinator?.openOnrampCurrencySelector()
    }
}

// MARK: - Private

private extension OnrampAmountViewModel {
    func bind() {
        interactor
            .currencyPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, currency in
                viewModel.update(currency: currency)
            }
            .store(in: &bag)

        decimalNumberTextFieldViewModel
            .debouncedValuePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, value in
                viewModel.textFieldValueDidChanged(amount: value)
            }
            .store(in: &bag)

        interactor
            .errorPublisher
            .map { $0.map { .error($0) } }
            .receive(on: DispatchQueue.main)
            .assign(to: \.bottomInfoText, on: self, ownership: .weak)
            .store(in: &bag)

        interactor
            .expectedTokenAmountPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amount in
                viewModel.updateCryptoAmount(amount: amount)
            }
            .store(in: &bag)
    }

    func update(currency: OnrampFiatCurrency?) {
        switch currency {
        case .none:
            // Equal to loading state
            fiatIconURL = nil
            currentFieldOptions = nil
            isLoading = true

        case .some(let currency):
            fiatIconURL = currency.identity.image
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: currency.precision)
            currentFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(
                fiatCurrencyCode: currency.identity.code
            )
//            updateCryptoAmount(amount: .none)
            isLoading = false
        }
    }

    func textFieldValueDidChanged(amount: Decimal?) {
        interactor.update(fiat: amount)
    }

    func updateCryptoAmount(amount: LoadingResult<Decimal?, Never>?) {
        switch amount {
        case .none:
            alternativeAmount = .initialized
        case .loading:
            alternativeAmount = .loading
        case .success(.some(let crypto)):
            if let formatted = formatter.string(from: crypto) {
                alternativeAmount = .loaded(text: "\(AppConstants.tildeSign) \(formatted)")
            } else {
                fallthrough
            }
        case .success(.none):
            alternativeAmount = .noData
        }
    }
}
