//
//  SendSummaryStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendSummaryStepBuilder {
    typealias ReturnValue = (step: SendSummaryStep, interactor: SendSummaryInteractor)

    let userWalletModel: UserWalletModel
    let walletModel: WalletModel
    let builder: SendModulesStepsBuilder

    func makeSendSummaryStep(
        sendTransactionSender: any SendTransactionSender,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        sendType: SendType
    ) -> ReturnValue {
        let interactor = makeSendSummaryInteractor(sendTransactionSender: sendTransactionSender)

        let viewModel = makeSendSummaryViewModel(
            interactor: interactor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            editableType: sendType.isSend ? .editable : .disable
        )

        let step = SendSummaryStep(
            viewModel: viewModel,
            interactor: interactor,
            tokenItem: walletModel.tokenItem,
            walletName: userWalletModel.name
        )

        return (step: step, interactor: interactor)
    }
}

// MARK: - Private

private extension SendSummaryStepBuilder {
    func makeSendSummaryViewModel(
        interactor: SendSummaryInteractor,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        editableType: SendSummaryViewModel.EditableType
    ) -> SendSummaryViewModel {
        let settings = SendSummaryViewModel.Settings(
            tokenItem: walletModel.tokenItem,
            editableType: editableType
        )

        return SendSummaryViewModel(
            settings: settings,
            interactor: interactor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory()
        )
    }

    func makeSendSummaryInteractor(sendTransactionSender: any SendTransactionSender) -> SendSummaryInteractor {
        CommonSendSummaryInteractor(
            sendTransactionSender: sendTransactionSender,
            descriptionBuilder: builder.makeSendTransactionSummaryDescriptionBuilder()
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
