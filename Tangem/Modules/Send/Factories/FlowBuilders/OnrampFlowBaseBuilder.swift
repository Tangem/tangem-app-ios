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
    let onrampAmountBuilder: OnrampAmountBuilder
    let onrampStepBuilder: OnrampStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(router: SendRoutable) -> SendViewModel {
        let (onrampManager, onrampRepository, onrampDataRepository) = builder.makeOnrampDependencies(
            userWalletId: userWalletModel.userWalletId.stringValue
        )

        let onrampModel = builder.makeOnrampModel(onrampManager: onrampManager, onrampRepository: onrampRepository)

        let providersBuilder = OnrampProvidersBuilder(
            io: (input: onrampModel, output: onrampModel),
            tokenItem: walletModel.tokenItem,
            paymentMethodsInput: onrampModel
        )

        let paymentMethodsBuilder = OnrampPaymentMethodsBuilder(
            io: (input: onrampModel, output: onrampModel),
            dataRepository: onrampDataRepository
        )

        let (onrampAmountViewModel, _) = onrampAmountBuilder.makeOnrampAmountViewModel(
            io: (input: onrampModel, output: onrampModel),
            onrampProvidersInput: onrampModel,
            coordinator: router
        )

        let sendAmountCompactViewModel = sendAmountStepBuilder.makeSendAmountCompactViewModel(
            input: onrampModel
        )

        let onrampProvidersCompactViewModel = providersBuilder.makeOnrampProvidersCompactViewModel()

        let onramp = onrampStepBuilder.makeOnrampStep(
            io: (input: onrampModel, output: onrampModel),
            onrampManager: onrampManager,
            onrampAmountViewModel: onrampAmountViewModel,
            onrampProvidersCompactViewModel: onrampProvidersCompactViewModel
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

        let dataBuilder = builder.makeOnrampBaseDataBuilder(
            onrampRepository: onrampRepository,
            onrampDataRepository: onrampDataRepository,
            providersBuilder: providersBuilder,
            paymentMethodsBuilder: paymentMethodsBuilder
        )

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

        onrampProvidersCompactViewModel.router = viewModel
        onrampModel.router = viewModel
        onrampModel.alertPresenter = viewModel

        return viewModel
    }
}
