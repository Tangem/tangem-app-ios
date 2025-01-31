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
    let source: SendCoordinator.Source
    let stakingValidatorsStepBuilder: StakingValidatorsStepBuilder
    let sendAmountStepBuilder: SendAmountStepBuilder
    let sendFeeStepBuilder: SendFeeStepBuilder
    let sendSummaryStepBuilder: SendSummaryStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(manager: some StakingManager, action: RestakingModel.Action? = nil, router: SendRoutable) -> SendViewModel {
        // no pending action == full balance staking
        let action = action ?? StakingAction(
            amount: (try? walletModel.getBalance()) ?? 0,
            validatorType: .empty,
            type: .stake
        )

        let restakingModel = builder.makeRestakingModel(stakingManager: manager, action: action)
        let notificationManager = builder.makeStakingNotificationManager()
        notificationManager.setup(provider: restakingModel, input: restakingModel)
        notificationManager.setupManager(with: restakingModel)

        let sendFeeCompactViewModel = sendFeeStepBuilder.makeSendFeeCompactViewModel(input: restakingModel)
        sendFeeCompactViewModel.bind(input: restakingModel)

        let actionType = builder.sendFlowActionType(actionType: action.displayType)
        let sendFinishAnalyticsLogger = builder.makeStakingFinishAnalyticsLogger(
            actionType: actionType,
            stakingValidatorsInput: restakingModel
        )

        let validators = stakingValidatorsStepBuilder.makeStakingValidatorsStep(
            io: (input: restakingModel, output: restakingModel),
            manager: manager,
            currentValidator: action.validatorInfo,
            actionType: actionType,
            sendFeeLoader: restakingModel
        )

        let sendAmountCompactViewModel = sendAmountStepBuilder.makeSendAmountCompactViewModel(input: restakingModel)

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: restakingModel, output: restakingModel),
            actionType: actionType,
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
            sendFinishAnalyticsLogger: sendFinishAnalyticsLogger,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            onrampAmountCompactViewModel: .none,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            onrampStatusCompactViewModel: .none
        )

        let stepsManager = CommonRestakingStepsManager(
            validatorsStep: validators.step,
            summaryStep: summary.step,
            finishStep: finish,
            actionType: actionType
        )

        summary.step.set(router: stepsManager)

        let interactor = CommonSendBaseInteractor(input: restakingModel, output: restakingModel)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            alertBuilder: builder.makeStakingAlertBuilder(),
            dataBuilder: builder.makeStakingBaseDataBuilder(input: restakingModel),
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            source: source,
            coordinator: router
        )
        stepsManager.set(output: viewModel)
        restakingModel.router = viewModel

        return viewModel
    }
}
