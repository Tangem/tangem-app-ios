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
import BlockchainSdk

#warning("TODO: move these to different files?")

protocol SendAmountViewModelInput {
    var userInputAmountValue: Amount? { get }
    var amountError: AnyPublisher<Error?, Never> { get }

    func didChangeFeeInclusion(_ isFeeIncluded: Bool)
}

class SendAmountViewModel: ObservableObject, Identifiable {
    let walletName: String
    let balance: String
    let tokenIconInfo: TokenIconInfo
    let currencyPickerDisabled: Bool
    let cryptoIconURL: URL?
    let cryptoCurrencyCode: String
    let fiatIconURL: URL?
    let fiatCurrencyCode: String
    let fiatCurrencySymbol: String
    let amountFractionDigits: Int

    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var useFiatCalculation = false
    @Published var amountAlternative: String?
    @Published var error: String?
    @Published var animatingAuxiliaryViewsOnAppear = false

    var currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions {
        useFiatCalculation ? fiatFieldOptions : cryptoFieldOptions
    }

    var didProperlyDisappear = false

    private weak var fiatCryptoAdapter: SendFiatCryptoAdapter?

    private let input: SendAmountViewModelInput
    private let cryptoFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    private let fiatFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    private let balanceValue: Decimal?
    private var bag: Set<AnyCancellable> = []

    init(input: SendAmountViewModelInput, fiatCryptoAdapter: SendFiatCryptoAdapter, walletInfo: SendWalletInfo) {
        self.input = input
        self.fiatCryptoAdapter = fiatCryptoAdapter
        balanceValue = walletInfo.balanceValue
        walletName = walletInfo.walletName
        balance = walletInfo.balance
        tokenIconInfo = walletInfo.tokenIconInfo
        amountFractionDigits = walletInfo.amountFractionDigits
        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: walletInfo.amountFractionDigits)

        currencyPickerDisabled = !walletInfo.canUseFiatCalculation

        cryptoIconURL = walletInfo.cryptoIconURL
        cryptoCurrencyCode = walletInfo.cryptoCurrencyCode

        let localizedCurrencySymbol = Locale.current.localizedCurrencySymbol(forCurrencyCode: walletInfo.fiatCurrencyCode)
        fiatIconURL = walletInfo.fiatIconURL
        fiatCurrencyCode = walletInfo.fiatCurrencyCode
        fiatCurrencySymbol = localizedCurrencySymbol ?? walletInfo.fiatCurrencyCode

        let factory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory(
            cryptoCurrencyCode: walletInfo.cryptoCurrencyCode,
            fiatCurrencyCode: walletInfo.fiatCurrencyCode
        )
        cryptoFieldOptions = factory.makeCryptoOptions()
        fiatFieldOptions = factory.makeFiatOptions()

        bind(from: input)
    }

    func onAppear() {
        fiatCryptoAdapter?.setCrypto(input.userInputAmountValue?.value)

        if animatingAuxiliaryViewsOnAppear {
            Analytics.log(.sendScreenReopened, params: [.source: .amount])
        } else {
            Analytics.log(.sendAmountScreenOpened)
        }
    }

    func setUserInputAmount(_ userInputAmount: Decimal?) {
        decimalNumberTextFieldViewModel.update(value: userInputAmount)
    }

    func didTapMaxAmount() {
        guard let balanceValue else { return }

        Analytics.log(.sendMaxAmountTapped)

        provideButtonHapticFeedback()

        fiatCryptoAdapter?.setCrypto(balanceValue)
    }

    private func bind(from input: SendAmountViewModelInput) {
        input
            .amountError
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self, ownership: .weak)
            .store(in: &bag)

        decimalNumberTextFieldViewModel
            .valuePublisher
            .sink { [weak self] decimal in
                self?.fiatCryptoAdapter?.setAmount(decimal)
            }
            .store(in: &bag)

        $useFiatCalculation
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, useFiatCalculation in
                let maximumFractionDigits = useFiatCalculation ? 2 : viewModel.amountFractionDigits
                viewModel.decimalNumberTextFieldViewModel.update(maximumFractionDigits: maximumFractionDigits)
                viewModel.provideSelectionHapticFeedback()
                viewModel.fiatCryptoAdapter?.setUseFiatCalculation(useFiatCalculation)
            }
            .store(in: &bag)

        fiatCryptoAdapter?
            .formattedAmountAlternativePublisher
            .assign(to: \.amountAlternative, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func provideButtonHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func provideSelectionHapticFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

extension SendAmountViewModel: AuxiliaryViewAnimatable {}

extension SendAmountViewModel: SendFiatCryptoAdapterInput {
    var amountPublisher: AnyPublisher<Decimal?, Never> {
        decimalNumberTextFieldViewModel.valuePublisher
    }
}
