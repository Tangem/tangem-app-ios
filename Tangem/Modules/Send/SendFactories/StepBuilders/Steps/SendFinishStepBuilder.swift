//
//  SendFinishStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendFinishStepBuilder {
    typealias ReturnValue = SendFinishStep

    let walletModel: WalletModel
    let builder: SendDependenciesBuilder

    func makeSendFinishStep(
        addressTextViewHeightModel: AddressTextViewHeightModel?
    ) -> ReturnValue {
        let viewModel = makeSendFinishViewModel(
            addressTextViewHeightModel: addressTextViewHeightModel
        )

        let step = SendFinishStep(viewModel: viewModel)

        return step
    }
}

// MARK: - Private

private extension SendFinishStepBuilder {
    func makeSendFinishViewModel(addressTextViewHeightModel: AddressTextViewHeightModel?) -> SendFinishViewModel {
        SendFinishViewModel(
            settings: .init(tokenItem: walletModel.tokenItem),
            addressTextViewHeightModel: addressTextViewHeightModel,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory(),
            feeAnalyticsParameterBuilder: builder.makeFeeAnalyticsParameterBuilder()
        )
    }

    func makeSendSummarySectionViewModelFactory() -> SendSummarySectionViewModelFactory {
        SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletModel.feeTokenItem.currencySymbol,
            feeCurrencyId: walletModel.feeTokenItem.currencyId,
            isFeeApproximate: builder.isFeeApproximate(),
            currencyId: walletModel.tokenItem.currencyId,
            tokenIconInfo: builder.makeTokenIconInfo()
        )
    }
}
