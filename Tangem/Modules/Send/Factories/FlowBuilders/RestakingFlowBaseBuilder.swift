//
//  RestakingFlowBaseBuilder.swift
//  TangemApp
//
//  Created by Dmitry Fedorov on 30.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct RestakingFlowBaseBuilder {
    let userWalletModel: UserWalletModel
    let walletModel: WalletModel
    let stakingValidatorsStepBuilder: StakingValidatorsStepBuilder
    let sendAmountStepBuilder: SendAmountStepBuilder
    let sendFeeStepBuilder: SendFeeStepBuilder
    let sendSummaryStepBuilder: SendSummaryStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(manager: some StakingManager, action: UnstakingModel.Action, router: SendRoutable) -> SendViewModel {
        let restakingModel = builder.makeRestakingModel(stakingManager: manager, action: action)
        let notificationManager = builder.makeStakingNotificationManager()
        notificationManager.setup(provider: restakingModel, input: restakingModel)
        notificationManager.setupManager(with: restakingModel)

        let sendFeeCompactViewModel = sendFeeStepBuilder.makeSendFeeCompactViewModel(input: restakingModel)
        sendFeeCompactViewModel.bind(input: restakingModel)

        let validators = stakingValidatorsStepBuilder.makeStakingValidatorsStep(
            io: (input: restakingModel, output: restakingModel),
            manager: manager,
            sendFeeLoader: restakingModel
        )

        let sendAmountCompactViewModel = sendAmountStepBuilder.makeSendAmountCompactViewModel(input: restakingModel)

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: restakingModel, output: restakingModel),
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
            input: restakingModel,
            actionType: .voteLocked,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let stepsManager = CommonRestakingStepsManager(
            validatorsStep: validators.step,
            summaryStep: summary.step,
            finishStep: finish,
            action: action
        )

        summary.step.set(router: stepsManager)

        let interactor = CommonSendBaseInteractor(input: restakingModel, output: restakingModel)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            alertBuilder: builder.makeStakingAlertBuilder(),
            dataBuilder: builder.makeSendBaseDataBuilder(input: restakingModel),
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            coordinator: router
        )
        stepsManager.set(output: viewModel)
        restakingModel.router = viewModel

        return viewModel
    }
}
