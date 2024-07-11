//
//  SendFlowFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 08.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendFlowFactory {
    private let userWalletModel: UserWalletModel
    private let walletModel: WalletModel

    init(userWalletModel: UserWalletModel, walletModel: WalletModel) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
    }

    func makeSendViewModel(router: SendRoutable) -> SendViewModel {
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let sendDestinationStepBuilder = SendDestinationStepBuilder(walletModel: walletModel, builder: builder)
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel, builder: builder)

        let baseBuilder = SendFlowBaseBuilder(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            sendAmountStepBuilder: sendAmountStepBuilder,
            sendDestinationStepBuilder: sendDestinationStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(router: router)
    }

    func makeSellViewModel(sellParameters: PredefinedSellParameters, router: SendRoutable) -> SendViewModel {
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel, builder: builder)

        let baseBuilder = SellFlowBaseBuilder(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(sellParameters: sellParameters, router: router)
    }
}
