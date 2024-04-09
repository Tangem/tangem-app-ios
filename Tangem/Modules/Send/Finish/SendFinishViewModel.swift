//
//  SendFinishViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 16.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

protocol SendFinishViewModelInput: AnyObject {
    var userInputAmountValue: Amount? { get }
    var destinationText: String? { get }
    var additionalField: (SendAdditionalFields, String)? { get }
    var feeValue: Fee? { get }
    var selectedFeeOption: FeeOption { get }

    var transactionTime: Date? { get }
    var transactionURL: URL? { get }
}

class SendFinishViewModel: ObservableObject {
    @Published var showHeader = false
    @Published var showButtons = false

    let transactionTime: String

    let destinationViewTypes: [SendDestinationSummaryViewType]
    let amountSummaryViewData: SendAmountSummaryViewData?
    let feeSummaryViewData: SendFeeSummaryViewModel?

    weak var router: SendFinishRoutable?

    private let transactionURL: URL

    init?(input: SendFinishViewModelInput, fiatCryptoValueProvider: SendFiatCryptoValueProvider, walletInfo: SendWalletInfo) {
        guard
            let destinationText = input.destinationText,
            let transactionTime = input.transactionTime,
            let transactionURL = input.transactionURL
        else {
            return nil
        }

        let sectionViewModelFactory = SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletInfo.feeCurrencySymbol,
            feeCurrencyId: walletInfo.feeCurrencyId,
            isFeeApproximate: walletInfo.isFeeApproximate,
            currencyId: walletInfo.currencyId,
            tokenIconInfo: walletInfo.tokenIconInfo
        )

        destinationViewTypes = sectionViewModelFactory.makeDestinationViewTypes(
            address: destinationText,
            additionalField: input.additionalField
        )
        amountSummaryViewData = sectionViewModelFactory.makeAmountViewData(
            from: fiatCryptoValueProvider.formattedAmount,
            amountAlternative: fiatCryptoValueProvider.formattedAmountAlternative
        )
        feeSummaryViewData = sectionViewModelFactory.makeFeeViewData(from: input.feeValue, feeOption: input.selectedFeeOption, animateTitleOnAppear: false)

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        self.transactionTime = formatter.string(from: transactionTime)
        self.transactionURL = transactionURL
    }

    func onAppear() {
        Analytics.log(.sendTransactionSentScreenOpened)

        showHeader = true
        showButtons = true
    }

    func explore() {
        Analytics.log(.sendButtonExplore)

        router?.explore(url: transactionURL)
    }

    func share() {
        Analytics.log(.sendButtonShare)

        router?.share(url: transactionURL)
    }
}
