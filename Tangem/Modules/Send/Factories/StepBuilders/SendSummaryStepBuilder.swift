//
//  SendSummaryStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendSummaryStepBuilder {
    typealias IO = (input: SendSummaryInput, output: SendSummaryOutput)
    typealias ReturnValue = (step: SendSummaryStep, interactor: SendSummaryInteractor)

    let walletModel: WalletModel
    let builder: SendDependenciesBuilder

    func makeSendSummaryStep(
        io: IO,
        actionType: SendFlowActionType,
        descriptionBuilder: any SendTransactionSummaryDescriptionBuilder,
        notificationManager: NotificationManager,
        editableType: SendSummaryViewModel.EditableType,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?
    ) -> ReturnValue {
        let interactor = makeSendSummaryInteractor(
            io: io,
            descriptionBuilder: descriptionBuilder
        )

        let viewModel = makeSendSummaryViewModel(
            interactor: interactor,
            actionType: actionType,
            notificationManager: notificationManager,
            editableType: editableType,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let step = SendSummaryStep(
            viewModel: viewModel,
            input: io.input,
            title: builder.summaryTitle(action: actionType),
            subtitle: builder.summarySubtitle(action: actionType)
        )

        return (step: step, interactor: interactor)
    }
}

// MARK: - Private

private extension SendSummaryStepBuilder {
    func makeSendSummaryViewModel(
        interactor: SendSummaryInteractor,
        actionType: SendFlowActionType,
        notificationManager: NotificationManager,
        editableType: SendSummaryViewModel.EditableType,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?
    ) -> SendSummaryViewModel {
        let settings = SendSummaryViewModel.Settings(
            tokenItem: walletModel.tokenItem,
            editableType: editableType,
            actionType: actionType
        )

        return SendSummaryViewModel(
            settings: settings,
            interactor: interactor,
            notificationManager: notificationManager,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )
    }

    func makeSendSummaryInteractor(
        io: IO,
        descriptionBuilder: any SendTransactionSummaryDescriptionBuilder
    ) -> SendSummaryInteractor {
        CommonSendSummaryInteractor(
            input: io.input,
            output: io.output,
            descriptionBuilder: descriptionBuilder
        )
    }
}
