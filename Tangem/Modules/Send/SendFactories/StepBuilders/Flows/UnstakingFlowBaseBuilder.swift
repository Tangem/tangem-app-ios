//
//  UnstakingFlowBaseBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct UnstakingFlowBaseBuilder {
    let userWalletModel: UserWalletModel
    let walletModel: WalletModel
    let sendAmountStepBuilder: SendAmountStepBuilder
    let sendFeeStepBuilder: SendFeeStepBuilder
    let sendSummaryStepBuilder: SendSummaryStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(manager: any StakingManager, balanceInfo: StakingBalanceInfo, router: SendRoutable) -> SendViewModel {
        let unstakingModel = builder.makeUnstakingModel(stakingManager: manager, balanceInfo: balanceInfo)
        let notificationManager = builder.makeStakingNotificationManager()
        notificationManager.setup(provider: unstakingModel, input: unstakingModel)

        let sendFeeCompactViewModel = sendFeeStepBuilder.makeSendFeeCompactViewModel(input: unstakingModel)
        sendFeeCompactViewModel.bind(input: unstakingModel)

        let sendAmountCompactViewModel = sendAmountStepBuilder.makeSendAmountCompactViewModel(input: unstakingModel)

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: unstakingModel, output: unstakingModel),
            actionType: .unstake,
            descriptionBuilder: builder.makeStakingTransactionSummaryDescriptionBuilder(),
            notificationManager: notificationManager,
            editableType: .noEditable,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: unstakingModel,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let stepsManager = CommonUnstakingStepsManager(
            provider: unstakingModel,
            summaryStep: summary.step,
            finishStep: finish
        )

        let interactor = CommonSendBaseInteractor(
            input: unstakingModel,
            output: unstakingModel,
            walletModel: walletModel,
            emailDataProvider: userWalletModel,
            stakingModel: .none
        )

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
