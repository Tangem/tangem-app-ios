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
    @ObservedObject var addressTextViewHeightModel: AddressTextViewHeightModel

    let transactionTime: String

    let destinationViewTypes: [SendDestinationSummaryViewType]
    let amountSummaryViewData: SendAmountSummaryViewData?
    let feeSummaryViewData: SendFeeSummaryViewModel?

    private let feeTypeAnalyticsParameter: Analytics.ParameterValue
    private let walletInfo: SendWalletInfo

    init?(input: SendFinishViewModelInput, fiatCryptoValueProvider: SendFiatCryptoValueProvider, addressTextViewHeightModel: AddressTextViewHeightModel, feeTypeAnalyticsParameter: Analytics.ParameterValue, walletInfo: SendWalletInfo) {
        guard
            let destinationText = input.destinationText,
            let transactionTime = input.transactionTime,
            let feeValue = input.feeValue
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
        feeSummaryViewData = sectionViewModelFactory.makeFeeViewData(from: .loaded(feeValue), feeOption: input.selectedFeeOption)

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        self.transactionTime = formatter.string(from: transactionTime)

        self.addressTextViewHeightModel = addressTextViewHeightModel
        self.feeTypeAnalyticsParameter = feeTypeAnalyticsParameter
        self.walletInfo = walletInfo
    }

    func onAppear() {
        Analytics.log(event: .sendTransactionSentScreenOpened, params: [
            .token: walletInfo.cryptoCurrencyCode,
            .feeType: feeTypeAnalyticsParameter.rawValue,
        ])

        withAnimation(SendView.Constants.defaultAnimation) {
            showHeader = true
        }
    }
}
