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
            io: io,
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
        io: IO,
        interactor: SendAmountInteractor,
        actionType: SendFlowActionType,
        sendQRCodeService: SendQRCodeService?
    ) -> SendAmountViewModel {
        let balanceFormatted: WalletModel.BalanceFormatted
        switch actionType {
        case .unstake:
            let balance = WalletModel.Balance(
                crypto: io.input.amount?.crypto,
                fiat: io.input.amount?.fiat
            )
            let cryptoFormatted = walletModel.formatter.formatCryptoBalance(
                balance.crypto,
                currencyCode: walletModel.tokenItem.currencySymbol
            )
            let fiatFormatted = walletModel.formatter.formatFiatBalance(balance.fiat)
            balanceFormatted = WalletModel.BalanceFormatted(crypto: cryptoFormatted, fiat: fiatFormatted)
        default:
            balanceFormatted = walletModel.availableBalanceFormatted
        }
        let initital = SendAmountViewModel.Settings(
            userWalletName: builder.walletName(),
            tokenItem: walletModel.tokenItem,
            tokenIconInfo: builder.makeTokenIconInfo(),
            balanceFormatted: Localization.commonCryptoFiatFormat(balanceFormatted.crypto, balanceFormatted.fiat),
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
