//
//  StakingValidatorsStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct StakingValidatorsStepBuilder {
    typealias IO = (input: StakingValidatorsInput, output: StakingValidatorsOutput)
    typealias ReturnValue = (step: StakingValidatorsStep, interactor: StakingValidatorsInteractor, compact: StakingValidatorsCompactViewModel)

    func makeStakingValidatorsStep(
        io: IO,
        manager: some StakingManager,
        currentValidator: ValidatorInfo? = nil,
        actionType: SendFlowActionType,
        sendFeeLoader: SendFeeLoader
    ) -> ReturnValue {
        let interactor = makeStakingValidatorsInteractor(
            io: io,
            manager: manager,
            currentValidator: currentValidator,
            actionType: actionType
        )
        let viewModel = makeStakingValidatorsViewModel(interactor: interactor)
        let step = StakingValidatorsStep(viewModel: viewModel, interactor: interactor, sendFeeLoader: sendFeeLoader)
        let compact = makeStakingValidatorsCompactViewModel(input: io.input)

        return (step: step, interactor: interactor, compact: compact)
    }
}

// MARK: - Private

private extension StakingValidatorsStepBuilder {
    func makeStakingValidatorsCompactViewModel(input: any StakingValidatorsInput) -> StakingValidatorsCompactViewModel {
        .init(input: input)
    }

    func makeStakingValidatorsViewModel(interactor: StakingValidatorsInteractor) -> StakingValidatorsViewModel {
        StakingValidatorsViewModel(interactor: interactor)
    }

    func makeStakingValidatorsInteractor(
        io: IO,
        manager: some StakingManager,
        currentValidator: ValidatorInfo?,
        actionType: SendFlowActionType
    ) -> StakingValidatorsInteractor {
        CommonStakingValidatorsInteractor(
            input: io.input,
            output: io.output,
            manager: manager,
            currentValidator: currentValidator,
            actionType: actionType
        )
    }
}
