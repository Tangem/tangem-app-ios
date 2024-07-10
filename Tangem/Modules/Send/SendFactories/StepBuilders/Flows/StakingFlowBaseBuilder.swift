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
        let notificationManager = builder.makeSendNotificationManager()
        let sendTransactionDispatcher = builder.makeSendTransactionDispatcher()
        let stakingModel = builder.makeStakingModel(sendTransactionDispatcher: sendTransactionDispatcher)

        let feeInteractor = builder.makeStakingFeeInteractor(input: stakingModel, output: stakingModel)

        let amount = sendAmountStepBuilder.makeSendAmountStep(
            io: (input: stakingModel, output: stakingModel),
            sendFeeInteractor: feeInteractor,
            sendQRCodeService: .none
        )

        let validators = stakingValidatorsStepBuilder.makeStakingValidatorsStep(
            io: (input: stakingModel, output: stakingModel),
            manager: manager
        )

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: stakingModel, output: stakingModel),
            sendTransactionDispatcher: sendTransactionDispatcher,
            notificationManager: notificationManager,
            addressTextViewHeightModel: .none,
            editableType: .editable
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(addressTextViewHeightModel: .none)

        // We have to set dependicies here after all setups is completed
        stakingModel.informationRelevanceService = builder.makeInformationRelevanceService(
            sendFeeInteractor: feeInteractor
        )

//        notificationManager.setup(input: stakingModel)

        summary.step.setup(sendAmountInput: stakingModel)
        summary.step.setup(sendFeeInteractor: feeInteractor)
        summary.step.setup(stakingValidatorsInput: stakingModel)

        finish.setup(sendAmountInput: stakingModel)
        finish.setup(sendFeeInteractor: feeInteractor)
        finish.setup(sendFinishInput: stakingModel)

        let stepsManager = CommonStakingStepsManager(
            amountStep: amount.step,
            validatorsStep: validators.step,
            summaryStep: summary.step,
            finishStep: finish
        )

        summary.step.set(router: stepsManager)

        let interactor = CommonSendBaseInteractor(input: stakingModel, output: stakingModel, walletModel: walletModel, emailDataProvider: userWalletModel)
        let viewModel = SendViewModel(interactor: interactor, stepsManager: stepsManager, coordinator: router)
        stepsManager.set(output: viewModel)

        return viewModel
    }
}
