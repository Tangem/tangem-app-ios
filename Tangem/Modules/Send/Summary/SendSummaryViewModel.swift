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

    var userInputAmountPublisher: AnyPublisher<Amount?, Never> { get }
    var destinationTextPublisher: AnyPublisher<String, Never> { get }
    var additionalFieldPublisher: AnyPublisher<(SendAdditionalFields, String)?, Never> { get }
    var feeValuePublisher: AnyPublisher<Fee?, Never> { get }
    var selectedFeeOptionPublisher: AnyPublisher<FeeOption, Never> { get }

    var isSending: AnyPublisher<Bool, Never> { get }
}

class SendSummaryViewModel: ObservableObject {
    let canEditAmount: Bool
    let canEditDestination: Bool

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
    @Published var feeSummaryViewData: SendFeeSummaryViewModel?

    @Published var animatingDestinationOnAppear = false
    @Published var animatingAmountOnAppear = false
    @Published var animatingFeeOnAppear = false
    @Published var showHint = false
    @Published var transactionDescription: String?
    @Published var showTransactionDescription = true

    @Published private(set) var notificationInputs: [NotificationViewInput] = []

    weak var router: SendSummaryRoutable?

    private let sectionViewModelFactory: SendSummarySectionViewModelFactory
    private var bag: Set<AnyCancellable> = []
    private let input: SendSummaryViewModelInput
    private let walletInfo: SendWalletInfo
    private let notificationManager: SendNotificationManager
    private let fiatCryptoValueProvider: SendFiatCryptoValueProvider

    init(input: SendSummaryViewModelInput, notificationManager: SendNotificationManager, fiatCryptoValueProvider: SendFiatCryptoValueProvider, walletInfo: SendWalletInfo) {
        self.input = input
        self.walletInfo = walletInfo
        self.notificationManager = notificationManager
        self.fiatCryptoValueProvider = fiatCryptoValueProvider

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
    }

    func onAppear() {
        withAnimation(SendView.Constants.defaultAnimation) {
            self.animatingDestinationOnAppear = false
            self.animatingAmountOnAppear = false
            self.animatingFeeOnAppear = false
        }

        Analytics.log(.sendConfirmScreenOpened)

        // For the sake of simplicity we're assuming that notifications aren't going to be created after the screen has been displayed
        showHint = false
        if notificationInputs.isEmpty, !AppSettings.shared.userDidTapSendScreenSummary {
            withAnimation(SendView.Constants.defaultAnimation.delay(SendView.Constants.animationDuration * 2)) {
                self.showHint = true
            }
        }

        // Show it with a delay, otherwise it will clash with the keyboard
        showTransactionDescription = false
        withAnimation(SendView.Constants.defaultAnimation.delay(SendView.Constants.animationDuration * 2)) {
            self.showTransactionDescription = true
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

        Publishers.CombineLatest(input.feeValuePublisher, input.selectedFeeOptionPublisher)
            .map { [weak self] feeValue, feeOption in
                self?.sectionViewModelFactory.makeFeeViewData(from: feeValue, feeOption: feeOption, animateTitleOnAppear: true)
            }
            .assign(to: \.feeSummaryViewData, on: self, ownership: .weak)
            .store(in: &bag)

        Publishers.CombineLatest(input.userInputAmountPublisher, input.feeValuePublisher)
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
            let amountCurrencyId = walletInfo.currencyId
        else {
            return nil
        }

        let converter = BalanceConverter()
        let amountInFiat = converter.convertToFiat(value: amount.value, from: amountCurrencyId)
        let feeInFiat = converter.convertToFiat(value: fee.amount.value, from: walletInfo.feeCurrencyId)

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
