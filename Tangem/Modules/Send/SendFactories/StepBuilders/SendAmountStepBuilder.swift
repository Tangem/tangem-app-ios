//
//  SendAmountStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendAmountStepBuilder {
    typealias IO = SendAmountInput & SendAmountOutput
    typealias ReturnValue = (step: SendAmountStep, interactor: SendAmountInteractor)

    let userWalletModel: UserWalletModel
    let walletModel: WalletModel
    let builder: SendDependenciesBuilder

    func makeSendAmountStep(io: IO, sendFeeInteractor: any SendFeeInteractor) -> ReturnValue {
        let interactor = makeSendAmountInteractor(io: io)

        let viewModel = makeSendAmountViewModel(
            interactor: interactor,
            predefinedAmount: nil
        )

        let step = SendAmountStep(
            viewModel: viewModel,
            interactor: interactor,
            sendFeeInteractor: sendFeeInteractor
        )

        return (step: step, interactor: interactor)
    }
}

// MARK: - Private

private extension SendAmountStepBuilder {
    func makeSendAmountViewModel(
        interactor: SendAmountInteractor,
        predefinedAmount: Decimal?
    ) -> SendAmountViewModel {
        let initital = SendAmountViewModel.Settings(
            userWalletName: userWalletModel.name,
            tokenItem: walletModel.tokenItem,
            tokenIconInfo: builder.makeTokenIconInfo(),
            balanceValue: walletModel.balanceValue ?? 0,
            balanceFormatted: walletModel.balance,
            currencyPickerData: builder.makeCurrencyPickerData(),
            predefinedAmount: predefinedAmount
        )

        return SendAmountViewModel(initial: initital, interactor: interactor)
    }

    private func makeSendAmountInteractor(io: IO) -> SendAmountInteractor {
        CommonSendAmountInteractor(
            input: io,
            output: io,
            tokenItem: walletModel.tokenItem,
            balanceValue: walletModel.balanceValue ?? 0,
            validator: makeSendAmountValidator(),
            type: .crypto
        )
    }

    private func makeSendAmountValidator() -> SendAmountValidator {
        CommonSendAmountValidator(tokenItem: walletModel.tokenItem, validator: walletModel.transactionValidator)
    }
}
