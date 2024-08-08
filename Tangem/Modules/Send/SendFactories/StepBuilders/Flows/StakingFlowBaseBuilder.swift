//
//  StakingFlowBaseBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct StakingFlowBaseBuilder {
    let userWalletModel: UserWalletModel
    let walletModel: WalletModel
    let sendAmountStepBuilder: SendAmountStepBuilder
    let stakingValidatorsStepBuilder: StakingValidatorsStepBuilder
    let sendFeeStepBuilder: SendFeeStepBuilder
    let sendSummaryStepBuilder: SendSummaryStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(manager: any StakingManager, router: SendRoutable) -> SendViewModel {
        let sendTransactionDispatcher = builder.makeStakingTransactionDispatcher()
        let stakingModel = builder.makeStakingModel(
            stakingManager: manager,
            sendTransactionDispatcher: sendTransactionDispatcher
        )

        let notificationManager = builder.makeStakingNotificationManager()
        notificationManager.setup(input: stakingModel)

        let sendFeeCompactViewModel = sendFeeStepBuilder.makeSendFeeCompactViewModel(input: stakingModel)
        sendFeeCompactViewModel.bind(input: stakingModel)

        let amount = sendAmountStepBuilder.makeSendAmountStep(
            io: (input: stakingModel, output: stakingModel),
            sendFeeLoader: stakingModel,
            sendQRCodeService: .none
        )

        let validators = stakingValidatorsStepBuilder.makeStakingValidatorsStep(
            io: (input: stakingModel, output: stakingModel),
            manager: manager
        )

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: stakingModel, output: stakingModel),
            actionType: .stake,
            sendTransactionDispatcher: sendTransactionDispatcher,
            notificationManager: notificationManager,
            editableType: .editable,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: stakingModel,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let stepsManager = CommonStakingStepsManager(
            amountStep: amount.step,
            validatorsStep: validators.step,
            summaryStep: summary.step,
            finishStep: finish
        )

        summary.step.set(router: stepsManager)

        let interactor = CommonSendBaseInteractor(input: stakingModel, output: stakingModel, walletModel: walletModel, emailDataProvider: userWalletModel)
        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            feeTokenItem: walletModel.feeTokenItem,
            coordinator: router
        )
        stepsManager.set(output: viewModel)

        return viewModel
    }
}
