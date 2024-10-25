//
//  OnrampFlowBaseBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct OnrampFlowBaseBuilder {
    let userWalletModel: UserWalletModel
    let walletModel: WalletModel
    let sendAmountStepBuilder: SendAmountStepBuilder
    let onrampStepBuilder: OnrampStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(onrampManager: some OnrampManager, router: SendRoutable) -> SendViewModel {
        let onrampModel = builder.makeOnrampModel(onrampManager: onrampManager)

        let onrampAmountViewModel = sendAmountStepBuilder.makeOnrampAmountViewModel(
            io: (input: onrampModel, output: onrampModel),
            sendAmountValidator: builder.makeOnrampAmountValidator(),
            amountModifier: .none
        )

        let sendAmountCompactViewModel = sendAmountStepBuilder.makeSendAmountCompactViewModel(
            input: onrampModel
        )

        let onramp = onrampStepBuilder.makeOnrampStep(
            io: (input: onrampModel, output: onrampModel),
            onrampManager: onrampManager,
            onrampAmountViewModel: onrampAmountViewModel
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: onrampModel,
            actionType: .onramp,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: .none
        )

        let stepsManager = CommonOnrampStepsManager(
            onrampStep: onramp.step,
            finishStep: finish,
            coordinator: router
        )

        onramp.step.setup(router: stepsManager)

        let interactor = CommonSendBaseInteractor(input: onrampModel, output: onrampModel)
        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            alertBuilder: builder.makeSendAlertBuilder(),
            dataBuilder: builder.makeSendBaseDataBuilder(input: onrampModel),
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            coordinator: router
        )

        stepsManager.set(output: viewModel)
        onrampModel.router = viewModel

        return viewModel
    }
}
