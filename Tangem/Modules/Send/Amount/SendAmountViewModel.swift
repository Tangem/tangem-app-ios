//
//  SendAmountViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SendAmountViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var animatingAuxiliaryViewsOnAppear: Bool = false

    let userWalletName: String
    let balance: String
    let tokenIconInfo: TokenIconInfo
    let currencyPickerData: SendCurrencyPickerData

    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var alternativeAmount: String?

    @Published var error: String?
    @Published var currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var amountType: SendAmountCalculationType = .crypto

    var isFiatCalculation: BindingValue<Bool> {
        .init(
            root: self,
            default: false,
            get: { $0.amountType == .fiat },
            set: { $0.amountType = $1 ? .fiat : .crypto }
        )
    }

    var didProperlyDisappear = false

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let interactor: SendAmountInteractor
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory

    private var bag: Set<AnyCancellable> = []

    init(
        initial: SendAmountViewModel.Settings,
        interactor: SendAmountInteractor
    ) {
        userWalletName = initial.userWalletName
        balance = initial.balanceFormatted
        tokenIconInfo = initial.tokenIconInfo
        currencyPickerData = initial.currencyPickerData

        prefixSuffixOptionsFactory = .init(
            cryptoCurrencyCode: initial.tokenItem.currencySymbol,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode
        )
        currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: initial.tokenItem.decimalCount)

        tokenItem = initial.tokenItem

        self.interactor = interactor

        bind()

        if let predefinedAmount = initial.predefinedAmount {
            setExternalAmount(predefinedAmount)
        }
    }

    func onAppear() {
        if animatingAuxiliaryViewsOnAppear {
            Analytics.log(.sendScreenReopened, params: [.source: .amount])
        } else {
            Analytics.log(.sendAmountScreenOpened)
        }
    }

    func userDidTapMaxAmount() {
        let amount = interactor.updateToMaxAmount()
        decimalNumberTextFieldViewModel.update(value: amount?.main)
        alternativeAmount = amount?.formatAlternative(currencySymbol: tokenItem.currencySymbol)
    }

    func setExternalAmount(_ amount: Decimal?) {
        decimalNumberTextFieldViewModel.update(value: amount)
        textFieldValueDidChanged(amount: amount)
    }
}

// MARK: - Private

private extension SendAmountViewModel {
    func bind() {
        $amountType
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amountType in
                viewModel.update(amountType: amountType)
            }
            .store(in: &bag)

        decimalNumberTextFieldViewModel
            .valuePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                viewModel.textFieldValueDidChanged(amount: value)
            }
            .store(in: &bag)

        interactor
            .errorPublisher()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, error in
                viewModel.error = error?.localizedDescription
            }
            .store(in: &bag)
    }

    func textFieldValueDidChanged(amount: Decimal?) {
        let amount = interactor.update(amount: amount)
        alternativeAmount = amount?.formatAlternative(currencySymbol: tokenItem.currencySymbol)
    }

    func update(amountType: SendAmountCalculationType) {
        let amount = interactor.update(type: amountType)
        alternativeAmount = amount?.formatAlternative(currencySymbol: tokenItem.currencySymbol)

        switch amountType {
        case .crypto:
            currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: tokenItem.decimalCount)
            decimalNumberTextFieldViewModel.update(value: amount?.crypto)
        case .fiat:
            currentFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions()
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: 2)
            decimalNumberTextFieldViewModel.update(value: amount?.fiat)
        }
    }
}

// MARK: - AuxiliaryViewAnimatable

extension SendAmountViewModel: AuxiliaryViewAnimatable {}

extension SendAmountViewModel {
    struct Settings {
        let userWalletName: String
        let tokenItem: TokenItem
        let tokenIconInfo: TokenIconInfo
        let balanceValue: Decimal
        let balanceFormatted: String
        let currencyPickerData: SendCurrencyPickerData

        let predefinedAmount: Decimal?
    }
}
