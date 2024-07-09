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
    var destinationText: String? { get }
    var additionalField: DestinationAdditionalFieldType { get }
    var feeValue: SendFee? { get }

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

    init?(
        initial: Initial,
        input: SendFinishViewModelInput,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        feeTypeAnalyticsParameter: Analytics.ParameterValue,
        walletInfo: SendWalletInfo,
        sectionViewModelFactory: SendSummarySectionViewModelFactory
    ) {
        // TODO: Move all logic into factory
        guard
            let destinationText = input.destinationText,
            let transactionTime = input.transactionTime,
            let feeValue = input.feeValue
        else {
            return nil
        }

        destinationViewTypes = sectionViewModelFactory.makeDestinationViewTypes(
            address: destinationText,
            additionalField: input.additionalField
        )

        let formattedAmount = initial.amount?.format(currencySymbol: initial.tokenItem.currencySymbol)
        let formattedAmountAlternative = initial.amount?.formatAlternative(currencySymbol: initial.tokenItem.currencySymbol)
        amountSummaryViewData = sectionViewModelFactory.makeAmountViewData(from: formattedAmount, amountAlternative: formattedAmountAlternative)
        feeSummaryViewData = sectionViewModelFactory.makeFeeViewData(from: feeValue)

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

extension SendFinishViewModel {
    struct Initial {
        let tokenItem: TokenItem
        let amount: SendAmount?
    }
}
