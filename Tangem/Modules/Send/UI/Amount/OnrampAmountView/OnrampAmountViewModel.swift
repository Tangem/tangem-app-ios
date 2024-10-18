//
//  OnrampAmountViewModel.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class OnrampAmountViewModel: ObservableObject {
    let tokenIconInfo: TokenIconInfo
    let currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions

    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var alternativeAmount: String?
    @Published var bottomInfoText: SendAmountViewModel.BottomInfoTextType?

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let interactor: SendAmountInteractor

    private var bag: Set<AnyCancellable> = []

    init(
        settings: Settings,
        interactor: SendAmountInteractor
    ) {
        self.interactor = interactor

        tokenIconInfo = settings.tokenIconInfo
        tokenItem = settings.tokenItem

        let prefixSuffixOptionsFactory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory(
            cryptoCurrencyCode: tokenItem.currencySymbol,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode
        )

        currentFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions()
        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: 2)

        bind()
    }
}

// MARK: - Private

private extension OnrampAmountViewModel {
    func bind() {
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
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, bottomInfoText in
                viewModel.bottomInfoText = bottomInfoText
            }
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

extension OnrampAmountViewModel {
    struct Settings {
        let tokenIconInfo: TokenIconInfo
        let tokenItem: TokenItem
    }
}
