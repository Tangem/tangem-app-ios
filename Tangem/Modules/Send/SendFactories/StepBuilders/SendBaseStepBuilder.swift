//
//  SendBaseStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendBaseStepBuilder {
    let userWalletModel: UserWalletModel
    let walletModel: WalletModel
    let sendAmountStepBuilder: SendAmountStepBuilder
    let sendDestinationStepBuilder: SendDestinationStepBuilder
    let sendFeeStepBuilder: SendFeeStepBuilder
    let sendSummaryStepBuilder: SendSummaryStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(sendType: SendType, router: SendRoutable) -> SendViewModel {
        let notificationManager = builder.makeSendNotificationManager()
        let addressTextViewHeightModel = AddressTextViewHeightModel()
        let sendTransactionDispatcher = builder.makeSendTransactionDispatcher()

        let sendModel = builder.makeSendModel(
            sendTransactionDispatcher: sendTransactionDispatcher,
            predefinedSellParameters: sendType.predefinedSellParameters,
            router: router
        )

        let fee = sendFeeStepBuilder.makeFeeSendStep(io: (input: sendModel, output: sendModel), notificationManager: notificationManager, router: router)
        let amount = sendAmountStepBuilder.makeSendAmountStep(io: (input: sendModel, output: sendModel), sendFeeInteractor: fee.interactor)
        let destination = sendDestinationStepBuilder.makeSendDestinationStep(
            io: (input: sendModel, output: sendModel),
            sendAmountInteractor: amount.interactor,
            sendFeeInteractor: fee.interactor,
            addressTextViewHeightModel: addressTextViewHeightModel,
            router: router
        )

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: sendModel, output: sendModel),
            sendTransactionDispatcher: sendTransactionDispatcher,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sendType: sendType
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            sendFeeInteractor: fee.interactor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sendType: sendType
        )

        // We have to set and fee.interactor here after all setups is complited
        sendModel.sendFeeInteractor = fee.interactor
        sendModel.informationRelevanceService = builder.makeInformationRelevanceService(
            sendFeeInteractor: fee.interactor
        )

        // Update the fees in case we in the sell flow
        // TODO: Will be updated
        // https://tangem.atlassian.net/browse/IOS-7195
        if !sendType.isSend {
            sendModel.updateFees()
        }

        notificationManager.setup(input: sendModel)

        summary.step.setup(sendDestinationInput: sendModel)
        summary.step.setup(sendAmountInput: sendModel)
        summary.step.setup(sendFeeInteractor: fee.interactor)

        finish.setup(sendDestinationInput: sendModel)
        finish.setup(sendAmountInput: sendModel)
        finish.setup(sendFeeInteractor: fee.interactor)
        finish.setup(sendFinishInput: sendModel)

        return SendViewModel(
            walletInfo: builder.makeSendWalletInfo(),
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            sendType: sendType,
            sendModel: sendModel,
            notificationManager: notificationManager,
            sendFeeInteractor: fee.interactor,
            keyboardVisibilityService: KeyboardVisibilityService(),
            feeAnalyticsParameterBuilder: builder.makeFeeAnalyticsParameterBuilder(),
            sendAmountViewModel: amount.step.viewModel,
            sendDestinationViewModel: destination.step.viewModel,
            sendFeeViewModel: fee.step.viewModel,
            sendSummaryViewModel: summary.step.viewModel,
            sendFinishViewModel: finish.viewModel,
            coordinator: router
        )
    }
}
