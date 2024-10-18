//
//  SendFlowFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 08.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

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
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel)

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
        let sendDestinationStepBuilder = SendDestinationStepBuilder(walletModel: walletModel, builder: builder)
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel)

        let baseBuilder = SellFlowBaseBuilder(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            sendDestinationStepBuilder: sendDestinationStepBuilder,
            sendAmountStepBuilder: sendAmountStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(sellParameters: sellParameters, router: router)
    }

    func makeStakingViewModel(manager: some StakingManager, router: SendRoutable) -> SendViewModel {
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let stakingValidatorsStepBuilder = StakingValidatorsStepBuilder()
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel)

        let baseBuilder = StakingFlowBaseBuilder(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            sendAmountStepBuilder: sendAmountStepBuilder,
            stakingValidatorsStepBuilder: stakingValidatorsStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(manager: manager, router: router)
    }

    func makeUnstakingViewModel(manager: some StakingManager, action: UnstakingModel.Action, router: SendRoutable) -> SendViewModel {
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel)

        let baseBuilder = UnstakingFlowBaseBuilder(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            sendAmountStepBuilder: sendAmountStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(manager: manager, action: action, router: router)
    }

    func makeRestakingViewModel(manager: some StakingManager, action: UnstakingModel.Action, router: SendRoutable) -> SendViewModel {
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let stakingValidatorsStepBuilder = StakingValidatorsStepBuilder()
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel)

        let baseBuilder = RestakingFlowBaseBuilder(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            stakingValidatorsStepBuilder: stakingValidatorsStepBuilder,
            sendAmountStepBuilder: sendAmountStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(manager: manager, action: action, router: router)
    }

    func makeStakingSingleActionViewModel(manager: some StakingManager, action: UnstakingModel.Action, router: SendRoutable) -> SendViewModel {
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel)

        let baseBuilder = StakingSingleActionFlowBaseBuilder(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            sendAmountStepBuilder: sendAmountStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(manager: manager, action: action, router: router)
    }

    func makeOnrampViewModel(router: SendRoutable) -> SendViewModel {
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let onrampStepBuilder = OnrampStepBuilder()
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel)
        let onrampManager = builder.makeOnrampManager(userWalletId: userWalletModel.userWalletId.stringValue)

        let baseBuilder = OnrampFlowBaseBuilder(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            sendAmountStepBuilder: sendAmountStepBuilder,
            onrampStepBuilder: onrampStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(onrampManager: onrampManager, router: router)
    }
}
