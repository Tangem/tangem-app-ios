//
//  SendFeeStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendFeeStepBuilder {
    typealias ReturnValue = (step: SendFeeStep, interactor: SendFeeInteractor)

    let userWalletModel: UserWalletModel
    let walletModel: WalletModel
    let builder: SendModulesStepsBuilder

    func makeFeeSendStep(notificationManager: SendNotificationManager, router: SendFeeRoutable) -> ReturnValue {
        let interactor = makeSendFeeInteractor()

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

    private func makeSendFeeInteractor() -> SendFeeInteractor { // predefinedAmount: Amount?, predefinedDestination: String?
        let customFeeService = CustomFeeServiceFactory(walletModel: walletModel).makeService()
        let interactor = CommonSendFeeInteractor(
            provider: makeSendFeeProvider(),
            defaultFeeOptions: builder.makeFeeOptions(),
            customFeeService: customFeeService
            //            predefinedAmount: predefinedAmount,
            //            predefinedDestination: predefinedDestination
        )

        customFeeService?.setup(input: interactor, output: interactor)
        return interactor
    }

    func makeSendFeeProvider() -> SendFeeProvider {
        CommonSendFeeProvider(walletModel: walletModel)
    }
}
