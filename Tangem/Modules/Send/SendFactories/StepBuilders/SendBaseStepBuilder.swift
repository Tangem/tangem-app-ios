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
    let builder: SendModulesStepsBuilder

    func makeSendViewModel(sendType: SendType, router: SendRoutable) -> SendViewModel {
        let notificationManager = builder.makeSendNotificationManager()
        let addressTextViewHeightModel: AddressTextViewHeightModel = .init()
        let sendTransactionSender = builder.makeSendTransactionSender()

        let fee = sendFeeStepBuilder.makeFeeSendStep(notificationManager: notificationManager, router: router)
        let amount = sendAmountStepBuilder.makeSendAmountStep(sendFeeInteractor: fee.interactor)
        let destination = sendDestinationStepBuilder.makeSendDestinationStep(
            sendAmountInteractor: amount.interactor,
            sendFeeInteractor: fee.interactor,
            addressTextViewHeightModel: addressTextViewHeightModel,
            router: router
        )

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
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

        let informationRelevanceService = builder.makeInformationRelevanceService(sendFeeInteractor: fee.interactor)

        let sendModel = builder.makeSendModel(
            sendAmountInteractor: amount.interactor,
            sendFeeInteractor: fee.interactor,
            informationRelevanceService: informationRelevanceService,
            sendTransactionSender: sendTransactionSender,
            type: sendType,
            router: router
        )

        let walletInfo = builder.makeSendWalletInfo()
        let initial = SendViewModel.Initial(feeOptions: builder.makeFeeOptions())
        fee.interactor.setup(input: sendModel, output: sendModel)

        notificationManager.setup(input: sendModel)

        destination.interactor.setup(input: sendModel, output: sendModel)
        amount.interactor.setup(input: sendModel, output: sendModel)
        fee.interactor.setup(input: sendModel, output: sendModel)

        summary.interactor.setup(input: sendModel, output: sendModel)
        summary.step.setup(sendDestinationInput: sendModel)
        summary.step.setup(sendAmountInput: sendModel)
        summary.step.setup(sendFeeInteractor: fee.interactor)

        finish.setup(sendDestinationInput: sendModel)
        finish.setup(sendAmountInput: sendModel)
        finish.setup(sendFeeInteractor: fee.interactor)
        finish.setup(sendFinishInput: sendModel)

        return SendViewModel(
            initial: initial,
            walletInfo: walletInfo,
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
