//
//  SendAmountCompactViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 19.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SendAmountCompactViewModel: ObservableObject, Identifiable {
    // Use the estimated size as initial value
    @Published var viewSize: CGSize = .init(width: 361, height: 143)

    @Published var amount: String?
    @Published private(set) var amountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions?

    @Published var alternativeAmount: String?
    @Published private(set) var alternativeAmountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions?

    let tokenIconInfo: TokenIconInfo

    private weak var input: SendAmountInput?
    private let tokenItem: TokenItem

    private lazy var prefixSuffixOptionsFactory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory(
        cryptoCurrencyCode: tokenItem.currencySymbol,
        fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode
    )

    private var bag: Set<AnyCancellable> = []

    init(
        input: SendAmountInput,
        tokenIconInfo: TokenIconInfo,
        tokenItem: TokenItem
    ) {
        self.input = input
        self.tokenIconInfo = tokenIconInfo
        self.tokenItem = tokenItem

        bind(input: input)
    }

    private func bind(input: SendAmountInput) {
        input.amountPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amount in
                viewModel.amount = amount?.format(
                    currencySymbol: viewModel.tokenItem.currencySymbol,
                    decimalCount: viewModel.tokenItem.decimalCount
                )

                viewModel.alternativeAmount = amount?.formatAlternative(
                    currencySymbol: viewModel.tokenItem.currencySymbol,
                    decimalCount: viewModel.tokenItem.decimalCount
                )

                viewModel.updateFieldOptions(from: amount)
            }
            .store(in: &bag)
    }

    private func updateFieldOptions(from amount: SendAmount?) {
        switch amount?.type {
        case .typical:
            amountFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
            alternativeAmountFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions()
        case .alternative:
            amountFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions()
            alternativeAmountFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
        case nil:
            amountFieldOptions = nil
            alternativeAmountFieldOptions = nil
        }
    }
}
