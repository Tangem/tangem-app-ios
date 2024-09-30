//
//  VoteFlowBaseBuilder.swift
//  TangemApp
//
//  Created by Dmitry Fedorov on 30.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct VoteFlowBaseBuilder {
    let userWalletModel: UserWalletModel
    let walletModel: WalletModel
    let stakingValidatorsStepBuilder: StakingValidatorsStepBuilder
    let sendAmountStepBuilder: SendAmountStepBuilder
    let sendFeeStepBuilder: SendFeeStepBuilder
    let sendSummaryStepBuilder: SendSummaryStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(manager: any StakingManager, action: UnstakingModel.Action, router: SendRoutable) -> SendViewModel {
        let voteModel = builder.makeVoteModel(stakingManager: manager, action: action)
        let notificationManager = builder.makeStakingNotificationManager()
        notificationManager.setup(provider: voteModel, input: voteModel)
        notificationManager.setupManager(with: voteModel)

        let sendFeeCompactViewModel = sendFeeStepBuilder.makeSendFeeCompactViewModel(input: voteModel)
        sendFeeCompactViewModel.bind(input: voteModel)

        let validators = stakingValidatorsStepBuilder.makeStakingValidatorsStep(
            io: (input: voteModel, output: voteModel),
            manager: manager,
            sendFeeLoader: voteModel
        )

        let sendAmountCompactViewModel = sendAmountStepBuilder.makeSendAmountCompactViewModel(input: voteModel)

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: voteModel, output: voteModel),
            actionType: .voteLocked,
            descriptionBuilder: builder.makeStakingTransactionSummaryDescriptionBuilder(),
            notificationManager: notificationManager,
            editableType: .noEditable,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: voteModel,
            actionType: .voteLocked,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let stepsManager = CommonVoteStepsManager(
            validatorsStep: validators.step,
            summaryStep: summary.step,
            finishStep: finish,
            action: action
        )

        summary.step.set(router: stepsManager)

        let interactor = CommonSendBaseInteractor(input: voteModel, output: voteModel)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            alertBuilder: builder.makeStakingAlertBuilder(),
            dataBuilder: builder.makeSendBaseDataBuilder(input: voteModel),
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            coordinator: router
        )
        stepsManager.set(output: viewModel)
        voteModel.router = viewModel

        return viewModel
    }
}
