//
//  SendSummaryViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

protocol SendSummaryViewModelInput: AnyObject {
    var canEditAmount: Bool { get }
    var canEditDestination: Bool { get }
    var feeOptions: [FeeOption] { get }

    var transactionAmountPublisher: AnyPublisher<Amount?, Never> { get }
    var destinationTextPublisher: AnyPublisher<String, Never> { get }
    var additionalFieldPublisher: AnyPublisher<(SendAdditionalFields, String)?, Never> { get }
    var feeValuePublisher: AnyPublisher<Fee?, Never> { get }
    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> { get }
    var selectedFeeOptionPublisher: AnyPublisher<FeeOption, Never> { get }

    var isSending: AnyPublisher<Bool, Never> { get }
}

class SendSummaryViewModel: ObservableObject {
    let canEditAmount: Bool
    let canEditDestination: Bool
    @Published var canEditFee: Bool = true

    var destinationBackground: Color {
        sectionBackground(canEdit: canEditDestination)
    }

    var amountBackground: Color {
        sectionBackground(canEdit: canEditAmount)
    }

    var walletName: String {
        walletInfo.walletName
    }

    var balance: String {
        walletInfo.balance
    }

    @Published var isSending = false
    @Published var alert: AlertBinder?

    @Published var destinationViewTypes: [SendDestinationSummaryViewType] = []
    @Published var amountSummaryViewData: SendAmountSummaryViewData?
    @Published var selectedFeeSummaryViewModel: SendFeeSummaryViewModel?
    @Published var deselectedFeeRowViewModels: [FeeRowViewModel] = []

    @Published var animatingDestinationOnAppear = false
    @Published var animatingAmountOnAppear = false
    @Published var animatingFeeOnAppear = false
    @Published var showHint = false
    @Published var transactionDescription: String?
    @Published var showTransactionDescription = true

    var didProperlyDisappear: Bool = true

    @Published private(set) var notificationInputs: [NotificationViewInput] = []

    weak var router: SendSummaryRoutable?

    private let sectionViewModelFactory: SendSummarySectionViewModelFactory
    private var bag: Set<AnyCancellable> = []
    private let input: SendSummaryViewModelInput
    private let walletInfo: SendWalletInfo
    private let notificationManager: SendNotificationManager
    private let fiatCryptoValueProvider: SendFiatCryptoValueProvider

    let addressTextViewHeightModel: AddressTextViewHeightModel

    init(input: SendSummaryViewModelInput, notificationManager: SendNotificationManager, fiatCryptoValueProvider: SendFiatCryptoValueProvider, addressTextViewHeightModel: AddressTextViewHeightModel, walletInfo: SendWalletInfo) {
        self.input = input
        self.walletInfo = walletInfo
        self.notificationManager = notificationManager
        self.fiatCryptoValueProvider = fiatCryptoValueProvider
        self.addressTextViewHeightModel = addressTextViewHeightModel

        sectionViewModelFactory = SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletInfo.feeCurrencySymbol,
            feeCurrencyId: walletInfo.feeCurrencyId,
            isFeeApproximate: walletInfo.isFeeApproximate,
            currencyId: walletInfo.currencyId,
            tokenIconInfo: walletInfo.tokenIconInfo
        )

        canEditAmount = input.canEditAmount
        canEditDestination = input.canEditDestination

        bind()
    }

    func setupAnimations(previousStep: SendStep) {
        switch previousStep {
        case .destination:
            animatingAmountOnAppear = true
            animatingFeeOnAppear = true
        case .amount:
            animatingDestinationOnAppear = true
            animatingFeeOnAppear = true
        case .fee:
            animatingDestinationOnAppear = true
            animatingAmountOnAppear = true
        default:
            break
        }

        showHint = false
        showTransactionDescription = false
    }

    func onAppear() {
        selectedFeeSummaryViewModel?.setAnimateTitleOnAppear(true)

        withAnimation(SendView.Constants.defaultAnimation) {
            self.animatingDestinationOnAppear = false
            self.animatingAmountOnAppear = false
            self.animatingFeeOnAppear = false
            self.showTransactionDescription = self.transactionDescription != nil
        }

        Analytics.log(.sendConfirmScreenOpened)

        // For the sake of simplicity we're assuming that notifications aren't going to be created after the screen has been displayed
        if notificationInputs.isEmpty, !AppSettings.shared.userDidTapSendScreenSummary {
            withAnimation(SendView.Constants.defaultAnimation.delay(SendView.Constants.animationDuration * 2)) {
                self.showHint = true
            }
        }
    }

    func didTapSummary(for step: SendStep) {
        if isSending {
            return
        }

        AppSettings.shared.userDidTapSendScreenSummary = true
        showHint = false

        router?.openStep(step)
    }

    private func bind() {
        input
            .isSending
            .assign(to: \.isSending, on: self, ownership: .weak)
            .store(in: &bag)

        Publishers.CombineLatest(input.destinationTextPublisher, input.additionalFieldPublisher)
            .map { [weak self] destination, additionalField in
                self?.sectionViewModelFactory.makeDestinationViewTypes(address: destination, additionalField: additionalField) ?? []
            }
            .assign(to: \.destinationViewTypes, on: self)
            .store(in: &bag)

        Publishers.CombineLatest(
            fiatCryptoValueProvider.formattedAmountPublisher,
            fiatCryptoValueProvider.formattedAmountAlternativePublisher
        )
        .compactMap { [weak self] formattedAmount, formattedAmountAlternative in
            self?.sectionViewModelFactory.makeAmountViewData(
                from: formattedAmount,
                amountAlternative: formattedAmountAlternative
            )
        }
        .assign(to: \.amountSummaryViewData, on: self, ownership: .weak)
        .store(in: &bag)

        Publishers.CombineLatest(input.feeValues, input.selectedFeeOptionPublisher)
            .sink { [weak self] feeValues, selectedFeeOption in
                guard let self else { return }

                var selectedFeeSummaryViewModel: SendFeeSummaryViewModel?
                var deselectedFeeRowViewModels: [FeeRowViewModel] = []

                for feeOption in input.feeOptions {
                    let feeValue = feeValues[feeOption] ?? .loading

                    if feeOption == selectedFeeOption {
                        selectedFeeSummaryViewModel = sectionViewModelFactory.makeFeeViewData(
                            from: feeValue,
                            feeOption: feeOption
                        )
                    } else {
                        let model = sectionViewModelFactory.makeDeselectedFeeRowViewModel(from: feeValue, feeOption: feeOption)
                        deselectedFeeRowViewModels.append(model)
                    }
                }

                self.selectedFeeSummaryViewModel = selectedFeeSummaryViewModel
                self.deselectedFeeRowViewModels = deselectedFeeRowViewModels
                canEditFee = feeValues.allSatisfy { $0.value.error == nil }
            }
            .store(in: &bag)

        Publishers.CombineLatest(input.transactionAmountPublisher, input.feeValuePublisher)
            .withWeakCaptureOf(self)
            .map { parameters -> String? in
                let (thisSendSummaryViewModel, (amount, fee)) = parameters

                return thisSendSummaryViewModel.makeTransactionDescription(amount: amount, fee: fee)
            }
            .assign(to: \.transactionDescription, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .summary)
            .sink { [weak self] notificationInputs in
                self?.notificationInputs = notificationInputs
            }
            .store(in: &bag)
    }

    private func sectionBackground(canEdit: Bool) -> Color {
        canEdit ? Colors.Background.action : Colors.Button.disabled
    }

    private func makeTransactionDescription(amount: Amount?, fee: Fee?) -> String? {
        guard
            let amount,
            let fee,
            let amountCurrencyId = walletInfo.currencyId,
            let feeCurrencyId = walletInfo.feeCurrencyId
        else {
            return nil
        }

        let converter = BalanceConverter()
        let amountInFiat = converter.convertToFiat(value: amount.value, from: amountCurrencyId)
        let feeInFiat = converter.convertToFiat(value: fee.amount.value, from: feeCurrencyId)

        let totalInFiat: Decimal?
        if let amountInFiat, let feeInFiat {
            totalInFiat = amountInFiat + feeInFiat
        } else {
            totalInFiat = nil
        }

        let formatter = BalanceFormatter()
        let totalInFiatFormatted = formatter.formatFiatBalance(totalInFiat)
        let feeInFiatFormatted = formatter.formatFiatBalance(feeInFiat)

        return Localization.sendSummaryTransactionDescription(totalInFiatFormatted, feeInFiatFormatted)
    }
}
