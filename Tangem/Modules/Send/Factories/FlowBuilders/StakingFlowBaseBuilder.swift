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

    func makeSendViewModel(manager: some StakingManager, router: SendRoutable) -> SendViewModel {
        let stakingModel = builder.makeStakingModel(stakingManager: manager)
        let notificationManager = builder.makeStakingNotificationManager()
        notificationManager.setup(provider: stakingModel, input: stakingModel)
        notificationManager.setupManager(with: stakingModel)

        let sendFeeCompactViewModel = sendFeeStepBuilder.makeSendFeeCompactViewModel(input: stakingModel)
        sendFeeCompactViewModel.bind(input: stakingModel)

        let amount = sendAmountStepBuilder.makeSendAmountStep(
            io: (input: stakingModel, output: stakingModel),
            actionType: .stake,
            sendFeeLoader: stakingModel,
            sendQRCodeService: .none,
            sendAmountValidator: builder.makeStakingSendAmountValidator(stakingManager: manager),
            amountModifier: builder.makeStakingAmountModifier(actionType: .stake),
            source: .staking
        )

        let validators = stakingValidatorsStepBuilder.makeStakingValidatorsStep(
            io: (input: stakingModel, output: stakingModel),
            manager: manager,
            actionType: .stake,
            sendFeeLoader: stakingModel
        )

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: stakingModel, output: stakingModel),
            actionType: .stake,
            descriptionBuilder: builder.makeStakingTransactionSummaryDescriptionBuilder(),
            notificationManager: notificationManager,
            editableType: .editable,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: stakingModel,
            actionType: .stake,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let stepsManager = CommonStakingStepsManager(
            provider: stakingModel,
            amountStep: amount.step,
            validatorsStep: validators.step,
            summaryStep: summary.step,
            finishStep: finish
        )

        summary.step.set(router: stepsManager)

        let interactor = CommonSendBaseInteractor(input: stakingModel, output: stakingModel)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            alertBuilder: builder.makeStakingAlertBuilder(),
            dataBuilder: builder.makeStakingBaseDataBuilder(input: stakingModel),
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            coordinator: router
        )
        stepsManager.set(output: viewModel)
        stakingModel.router = viewModel

        return viewModel
    }
}
