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
    typealias ReturnValue = (step: SendFeeStep, interactor: SendFeeInteractor, compact: SendFeeCompactViewModel)

    let walletModel: WalletModel
    let builder: SendDependenciesBuilder

    func makeFeeSendStep(io: IO, notificationManager: NotificationManager, router: SendFeeRoutable) -> ReturnValue {
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
            feeTokenItem: walletModel.feeTokenItem,
            feeAnalyticsParameterBuilder: builder.makeFeeAnalyticsParameterBuilder()
        )

        let compact = makeSendFeeCompactViewModel(input: io.input)

        return (step: step, interactor: interactor, compact: compact)
    }

    func makeSendFeeCompactViewModel(input: SendFeeInput) -> SendFeeCompactViewModel {
        .init(
            input: input,
            feeTokenItem: walletModel.feeTokenItem,
            isFeeApproximate: builder.isFeeApproximate()
        )
    }
}

// MARK: - Private

private extension SendFeeStepBuilder {
    func makeSendFeeViewModel(
        sendFeeInteractor: SendFeeInteractor,
        notificationManager: NotificationManager,
        router: SendFeeRoutable
    ) -> SendFeeViewModel {
        let settings = SendFeeViewModel.Settings(feeTokenItem: walletModel.feeTokenItem)

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
