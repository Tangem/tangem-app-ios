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

class OnrampAmountViewModel: ObservableObject {
    @Published var fiatIconURL: URL?
    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var alternativeAmount: String?
    @Published var bottomInfoText: SendAmountViewModel.BottomInfoTextType?
    @Published var currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions?

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let onrampInput: OnrampInput
    private let interactor: SendAmountInteractor
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory = .init()

    private var bag: Set<AnyCancellable> = []

    init(
        tokenItem: TokenItem,
        onrampInput: OnrampInput,
        interactor: SendAmountInteractor
    ) {
        self.interactor = interactor
        self.onrampInput = onrampInput
        self.tokenItem = tokenItem

        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: 2)

        bind()
    }
}

// MARK: - Private

private extension OnrampAmountViewModel {
    func bind() {
        onrampInput
            .currencyPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, currency in
                viewModel.fiatIconURL = currency.identity.image
                viewModel.decimalNumberTextFieldViewModel.update(maximumFractionDigits: currency.precision)
                viewModel.currentFieldOptions = viewModel.prefixSuffixOptionsFactory.makeFiatOptions(
                    fiatCurrencyCode: currency.identity.code
                )
            }
            .store(in: &bag)

        decimalNumberTextFieldViewModel
            .valuePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, value in
                viewModel.textFieldValueDidChanged(amount: value)
            }
            .store(in: &bag)

        interactor
            .infoTextPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.bottomInfoText, on: self, ownership: .weak)
            .store(in: &bag)

        interactor
            .externalAmountPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amount in
                viewModel.setExternalAmount(amount?.main)
                viewModel.alternativeAmount = amount?.formatAlternative(
                    currencySymbol: viewModel.tokenItem.currencySymbol,
                    decimalCount: viewModel.tokenItem.decimalCount
                )
            }
            .store(in: &bag)
    }

    func setExternalAmount(_ amount: Decimal?) {
        decimalNumberTextFieldViewModel.update(value: amount)
        textFieldValueDidChanged(amount: amount)
    }

    func textFieldValueDidChanged(amount: Decimal?) {
        let amount = interactor.update(amount: amount)
        alternativeAmount = amount?.formatAlternative(
            currencySymbol: tokenItem.currencySymbol,
            decimalCount: tokenItem.decimalCount
        )
    }
}
