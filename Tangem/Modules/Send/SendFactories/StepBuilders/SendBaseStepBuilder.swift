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
        let sendTransactionSender = builder.makeSendTransactionSender()

        let sendModel = builder.makeSendModel(
            sendTransactionSender: sendTransactionSender,
            type: sendType,
            router: router
        )

        let fee = sendFeeStepBuilder.makeFeeSendStep(io: sendModel, notificationManager: notificationManager, router: router)
        let amount = sendAmountStepBuilder.makeSendAmountStep(io: sendModel, sendFeeInteractor: fee.interactor)
        let destination = sendDestinationStepBuilder.makeSendDestinationStep(
            io: sendModel,
            sendAmountInteractor: amount.interactor,
            sendFeeInteractor: fee.interactor,
            addressTextViewHeightModel: addressTextViewHeightModel,
            router: router
        )

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: sendModel,
            sendTransactionSender: sendTransactionSender,
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
            initial: .init(feeOptions: builder.makeFeeOptions()),
            walletInfo: builder.makeSendWalletInfo(),
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            sendType: sendType,
            sendModel: sendModel,
            notificationManager: notificationManager,
            sendFeeInteractor: fee.interactor,
            keyboardVisibilityService: KeyboardVisibilityService(),
            sendAmountViewModel: amount.step.viewModel,
            sendDestinationViewModel: destination.step.viewModel,
            sendFeeViewModel: fee.step.viewModel,
            sendSummaryViewModel: summary.step.viewModel,
            sendFinishViewModel: finish.viewModel,
            coordinator: router
        )
    }
}
