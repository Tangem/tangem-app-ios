//
//  SendModulesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 08.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendModulesFactory {
    private let userWalletModel: UserWalletModel
    private let walletModel: WalletModel

    init(userWalletModel: UserWalletModel, walletModel: WalletModel) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
    }

    func makeSendViewModel(sendType: SendType, router: SendRoutable) -> SendViewModel {
        let builder = SendDependenciesBuilder(userWalletName: userWalletModel.name, walletModel: walletModel, userWalletModel: userWalletModel)
        let sendAmountStepBuilder = SendAmountStepBuilder(userWalletModel: userWalletModel, walletModel: walletModel, builder: builder)
        let sendDestinationStepBuilder = SendDestinationStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(userWalletModel: userWalletModel, walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(userWalletModel: userWalletModel, walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(userWalletModel: userWalletModel, walletModel: walletModel, builder: builder)

        let baseBuilder = SendBaseStepBuilder(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            sendAmountStepBuilder: sendAmountStepBuilder,
            sendDestinationStepBuilder: sendDestinationStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(sendType: sendType, router: router)
    }
}
