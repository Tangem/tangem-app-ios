//
//  StakingSingleActionFlowBaseBuilder.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 03.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct StakingSingleActionFlowBaseBuilder {
    let userWalletModel: UserWalletModel
    let walletModel: WalletModel
    let sendAmountStepBuilder: SendAmountStepBuilder
    let sendFeeStepBuilder: SendFeeStepBuilder
    let sendSummaryStepBuilder: SendSummaryStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(manager: any StakingManager, action: UnstakingModel.Action, router: SendRoutable) -> SendViewModel {
        let rewardsModel = builder.makeStakingSingleActionModel(stakingManager: manager, action: action)
        let notificationManager = builder.makeStakingNotificationManager()
        notificationManager.setup(provider: rewardsModel, input: rewardsModel)
        notificationManager.setupManager(with: rewardsModel)

        let sendAmountCompactViewModel = sendAmountStepBuilder.makeSendAmountCompactViewModel(input: rewardsModel)

        let actionType = builder.sendFlowActionType(actionType: action.type)

        let sendFeeCompactViewModel = sendFeeStepBuilder.makeSendFeeCompactViewModel(input: rewardsModel)
        sendFeeCompactViewModel.bind(input: rewardsModel)

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: rewardsModel, output: rewardsModel),
            actionType: actionType,
            descriptionBuilder: builder.makeStakingTransactionSummaryDescriptionBuilder(),
            notificationManager: notificationManager,
            editableType: .noEditable,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: rewardsModel,
            actionType: actionType,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let stepsManager = CommonStakingSingleActionStepsManager(
            summaryStep: summary.step,
            finishStep: finish,
            action: action
        )

        let interactor = CommonSendBaseInteractor(input: rewardsModel, output: rewardsModel)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            alertBuilder: builder.makeStakingAlertBuilder(),
            dataBuilder: builder.makeSendBaseDataBuilder(input: rewardsModel),
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            coordinator: router
        )
        stepsManager.set(output: viewModel)
        rewardsModel.router = viewModel

        return viewModel
    }
}
