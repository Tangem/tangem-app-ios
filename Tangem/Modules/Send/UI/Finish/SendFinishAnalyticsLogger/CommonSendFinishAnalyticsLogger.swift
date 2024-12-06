//
//  CommonSendFinishAnalyticsLogger.swift
//  TangemApp
//
//  Created by Sergey Balashov on 03.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CommonSendFinishAnalyticsLogger: SendFinishAnalyticsLogger {
    private let tokenItem: TokenItem
    private let feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder
    private weak var sendFeeInput: SendFeeInput?

    init(
        tokenItem: TokenItem,
        feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder,
        sendFeeInput: SendFeeInput
    ) {
        self.tokenItem = tokenItem
        self.feeAnalyticsParameterBuilder = feeAnalyticsParameterBuilder
        self.sendFeeInput = sendFeeInput
    }

    func onAppear() {
        let feeTypeAnalyticsParameter = feeAnalyticsParameterBuilder.analyticsParameter(
            selectedFee: sendFeeInput?.selectedFee.option
        )

        Analytics.log(event: .sendTransactionSentScreenOpened, params: [
            .token: tokenItem.currencySymbol,
            .feeType: feeTypeAnalyticsParameter.rawValue,
        ])
    }
}
