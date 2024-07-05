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

    let userWalletModel: UserWalletModel
    let walletModel: WalletModel
    let builder: SendDependenciesBuilder

    func makeSendFinishStep(
        sendFeeInteractor: SendFeeInteractor,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        sendType: SendType
    ) -> ReturnValue {
        let viewModel = makeSendFinishViewModel(
            addressTextViewHeightModel: addressTextViewHeightModel
        )

        let step = SendFinishStep(
            viewModel: viewModel,
            tokenItem: walletModel.tokenItem,
            sendFeeInteractor: sendFeeInteractor,
            feeAnalyticsParameterBuilder: builder.makeFeeAnalyticsParameterBuilder()
        )

        return step
    }
}

// MARK: - Private

private extension SendFinishStepBuilder {
    func makeSendFinishViewModel(addressTextViewHeightModel: AddressTextViewHeightModel) -> SendFinishViewModel {
        let settings = SendFinishViewModel.Settings(
            tokenItem: walletModel.tokenItem,
            isFixedFee: builder.makeFeeOptions().count == 1
        )

        return SendFinishViewModel(
            settings: settings,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory()
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
