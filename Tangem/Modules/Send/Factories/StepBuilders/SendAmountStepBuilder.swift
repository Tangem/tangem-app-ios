//
//  SendAmountStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct SendAmountStepBuilder {
    typealias IO = (input: SendAmountInput, output: SendAmountOutput)
    typealias ReturnValue = (step: SendAmountStep, interactor: SendAmountInteractor, compact: SendAmountCompactViewModel)

    let walletModel: WalletModel
    let builder: SendDependenciesBuilder

    func makeSendAmountStep(
        io: IO,
        actionType: SendFlowActionType,
        sendFeeLoader: any SendFeeLoader,
        sendQRCodeService: SendQRCodeService?,
        sendAmountValidator: SendAmountValidator,
        amountModifier: SendAmountModifier?,
        source: SendModel.PredefinedValues.Source
    ) -> ReturnValue {
        let interactor = makeSendAmountInteractor(
            io: io,
            sendAmountValidator: sendAmountValidator,
            amountModifier: amountModifier,
            type: .crypto
        )
        let viewModel = makeSendAmountViewModel(
            interactor: interactor,
            actionType: actionType,
            sendQRCodeService: sendQRCodeService
        )

        let step = SendAmountStep(
            viewModel: viewModel,
            interactor: interactor,
            sendFeeLoader: sendFeeLoader,
            source: source
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

    func makeOnrampAmountViewModel(
        io: IO,
        sendAmountValidator: SendAmountValidator
    ) -> OnrampAmountViewModel {
        let interactor = makeSendAmountInteractor(
            io: io,
            sendAmountValidator: sendAmountValidator,
            amountModifier: nil,
            type: .fiat
        )

        return OnrampAmountViewModel(tokenItem: walletModel.tokenItem, interactor: interactor)
    }
}

// MARK: - Private

private extension SendAmountStepBuilder {
    func makeSendAmountViewModel(
        interactor: SendAmountInteractor,
        actionType: SendFlowActionType,
        sendQRCodeService: SendQRCodeService?
    ) -> SendAmountViewModel {
        let initital = SendAmountViewModel.Settings(
            userWalletName: builder.walletName(),
            tokenItem: walletModel.tokenItem,
            tokenIconInfo: builder.makeTokenIconInfo(),
            balanceValue: walletModel.balanceValue ?? 0,
            balanceFormatted: Localization.commonCryptoFiatFormat(walletModel.balance, walletModel.fiatBalance),
            currencyPickerData: builder.makeCurrencyPickerData(),
            actionType: actionType
        )

        return SendAmountViewModel(
            initial: initital,
            interactor: interactor,
            sendQRCodeService: sendQRCodeService
        )
    }

    private func makeSendAmountInteractor(
        io: IO,
        sendAmountValidator: SendAmountValidator,
        amountModifier: SendAmountModifier?,
        type: SendAmountCalculationType
    ) -> SendAmountInteractor {
        CommonSendAmountInteractor(
            input: io.input,
            output: io.output,
            tokenItem: walletModel.tokenItem,
            balanceValue: walletModel.balanceValue ?? 0,
            validator: sendAmountValidator,
            amountModifier: amountModifier,
            type: type
        )
    }
}
