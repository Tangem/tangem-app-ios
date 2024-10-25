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

    func makeSendViewModel(router: SendRoutable) -> SendViewModel {
        let expressAPIProvider = ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletModel.userWalletId.stringValue, logger: AppLog.shared)
        let onrampRepository = builder.makeOnrampRepository()

        let onrampManager = TangemExpressFactory().makeOnrampManager(
            expressAPIProvider: expressAPIProvider,
            onrampRepository: onrampRepository,
            logger: AppLog.shared
        )

        let onrampModel = builder.makeOnrampModel(onrampManager: onrampManager, onrampRepository: onrampRepository)

        let onrampAmountViewModel = sendAmountStepBuilder.makeOnrampAmountViewModel(
            io: (input: onrampModel, output: onrampModel),
            onrampInput: onrampModel,
            sendAmountValidator: builder.makeOnrampAmountValidator()
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
            coordinator: router,
            // If user already has saved country in the repository then the bottom sheet will not show
            // And we can show keyboard safely
            shouldActivateKeyboard: onrampRepository.preferenceCountry != nil
        )

        onramp.step.setup(router: stepsManager)

        let dataBuilder = builder.makeOnrampBaseDataBuilder(input: onrampModel, onrampRepository: onrampRepository)
        let interactor = CommonSendBaseInteractor(input: onrampModel, output: onrampModel)
        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            alertBuilder: builder.makeSendAlertBuilder(),
            dataBuilder: dataBuilder,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            coordinator: router
        )

        stepsManager.set(output: viewModel)
        onrampModel.router = viewModel
        onrampModel.alertPresenter = viewModel

        return viewModel
    }
}
