//
//  SendFinishStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendFinishStepBuilder {
    typealias ReturnValue = SendFinishStep

    let walletModel: WalletModel

    func makeSendFinishStep(
        input: SendFinishInput,
        sendFinishAnalyticsLogger: SendFinishAnalyticsLogger,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        onrampAmountCompactViewModel: OnrampAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?,
        onrampStatusCompactViewModel: OnrampStatusCompactViewModel?
    ) -> ReturnValue {
        let viewModel = makeSendFinishViewModel(
            input: input,
            sendFinishAnalyticsLogger: sendFinishAnalyticsLogger,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            onrampAmountCompactViewModel: onrampAmountCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            onrampStatusCompactViewModel: onrampStatusCompactViewModel
        )

        let step = SendFinishStep(viewModel: viewModel)

        return step
    }
}

// MARK: - Private

private extension SendFinishStepBuilder {
    func makeSendFinishViewModel(
        input: SendFinishInput,
        sendFinishAnalyticsLogger: SendFinishAnalyticsLogger,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        onrampAmountCompactViewModel: OnrampAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?,
        onrampStatusCompactViewModel: OnrampStatusCompactViewModel?
    ) -> SendFinishViewModel {
        SendFinishViewModel(
            input: input,
            sendFinishAnalyticsLogger: sendFinishAnalyticsLogger,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            onrampAmountCompactViewModel: onrampAmountCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            onrampStatusCompactViewModel: onrampStatusCompactViewModel
        )
    }
}
