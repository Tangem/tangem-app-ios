//
//  SendFeeStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendFeeStepBuilder {
    typealias IO = (input: SendFeeInput, output: SendFeeOutput)
    typealias ReturnValue = (step: SendFeeStep, interactor: SendFeeInteractor)

    let walletModel: WalletModel
    let builder: SendDependenciesBuilder

    func makeFeeSendStep(io: IO, notificationManager: SendNotificationManager, router: SendFeeRoutable) -> ReturnValue {
        let interactor = makeSendFeeInteractor(io: io)

        let viewModel = makeSendFeeViewModel(
            sendFeeInteractor: interactor,
            notificationManager: notificationManager,
            router: router
        )

        let step = SendFeeStep(
            viewModel: viewModel,
            interactor: interactor,
            notificationManager: notificationManager,
            tokenItem: walletModel.tokenItem,
            feeAnalyticsParameterBuilder: builder.makeFeeAnalyticsParameterBuilder()
        )

        return (step: step, interactor: interactor)
    }
}

// MARK: - Private

private extension SendFeeStepBuilder {
    func makeSendFeeViewModel(
        sendFeeInteractor: SendFeeInteractor,
        notificationManager: SendNotificationManager,
        router: SendFeeRoutable
    ) -> SendFeeViewModel {
        let settings = SendFeeViewModel.Settings(tokenItem: walletModel.tokenItem)

        return SendFeeViewModel(
            settings: settings,
            interactor: sendFeeInteractor,
            notificationManager: notificationManager,
            router: router
        )
    }

    private func makeSendFeeInteractor(io: IO) -> SendFeeInteractor {
        let customFeeService = CustomFeeServiceFactory(walletModel: walletModel).makeService()
        let interactor = CommonSendFeeInteractor(
            input: io.input,
            output: io.output,
            provider: makeSendFeeProvider(),
            defaultFeeOptions: builder.makeFeeOptions(),
            customFeeService: customFeeService
        )

        customFeeService?.setup(input: interactor, output: interactor)
        return interactor
    }

    func makeSendFeeProvider() -> SendFeeProvider {
        CommonSendFeeProvider(walletModel: walletModel)
    }
}
