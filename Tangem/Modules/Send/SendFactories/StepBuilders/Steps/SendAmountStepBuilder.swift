//
//  SendAmountStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendAmountStepBuilder {
    typealias IO = (input: SendAmountInput, output: SendAmountOutput)
    typealias ReturnValue = (step: SendAmountStep, interactor: SendAmountInteractor, compact: SendAmountCompactViewModel)

    let walletModel: WalletModel
    let builder: SendDependenciesBuilder

    func makeSendAmountStep(
        io: IO,
        sendFeeLoader: any SendFeeLoader,
        sendQRCodeService: SendQRCodeService?,
        sendAmountValidator: SendAmountValidator
    ) -> ReturnValue {
        let interactor = makeSendAmountInteractor(io: io, sendAmountValidator: sendAmountValidator)
        let viewModel = makeSendAmountViewModel(interactor: interactor, sendQRCodeService: sendQRCodeService)

        let step = SendAmountStep(
            viewModel: viewModel,
            interactor: interactor,
            sendFeeLoader: sendFeeLoader
        )

        let compact = makeSendAmountCompactViewModel(input: io.input)
        return (step: step, interactor: interactor, compact: compact)
    }

    func makeSendAmountCompactViewModel(input: SendAmountInput) -> SendAmountCompactViewModel {
        .init(
            input: input,
            tokenIconInfo: builder.makeTokenIconInfo(),
            tokenItem: walletModel.tokenItem
        )
    }
}

// MARK: - Private

private extension SendAmountStepBuilder {
    func makeSendAmountViewModel(
        interactor: SendAmountInteractor,
        sendQRCodeService: SendQRCodeService?
    ) -> SendAmountViewModel {
        let initital = SendAmountViewModel.Settings(
            userWalletName: builder.walletName(),
            tokenItem: walletModel.tokenItem,
            tokenIconInfo: builder.makeTokenIconInfo(),
            balanceValue: walletModel.balanceValue ?? 0,
            balanceFormatted: Localization.sendWalletBalanceFormat(walletModel.balance, walletModel.fiatBalance),
            currencyPickerData: builder.makeCurrencyPickerData()
        )

        return SendAmountViewModel(
            initial: initital,
            interactor: interactor,
            sendQRCodeService: sendQRCodeService
        )
    }

    private func makeSendAmountInteractor(io: IO, sendAmountValidator: SendAmountValidator) -> SendAmountInteractor {
        CommonSendAmountInteractor(
            input: io.input,
            output: io.output,
            tokenItem: walletModel.tokenItem,
            balanceValue: walletModel.balanceValue ?? 0,
            validator: sendAmountValidator,
            type: .crypto
        )
    }
}
