//
//  StakingValidatorsStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct StakingValidatorsStepBuilder {
    typealias IO = (input: StakingValidatorsInput, output: StakingValidatorsOutput)
    typealias ReturnValue = (step: StakingValidatorsStep, interactor: StakingValidatorsInteractor)

    let walletModel: WalletModel
    let builder: SendDependenciesBuilder

    func makeSendFinishStep(
        io: IO,
        addressTextViewHeightModel: AddressTextViewHeightModel
    ) -> ReturnValue {

        let interactor = makeStakingValidatorsInteractor(io: io)
        let viewModel = makeSendFinishViewModel(interactor: interactor)

        let step = StakingValidatorsStep(viewModel: viewModel, interactor: interactor)

        return (step: step, interactor: interactor)
    }
}

// MARK: - Private

private extension StakingValidatorsStepBuilder {
    func makeSendFinishViewModel(interactor: StakingValidatorsInteractor) -> StakingValidatorsViewModel {
        StakingValidatorsViewModel(interactor: interactor)
    }

    func makeStakingValidatorsInteractor(io: IO) -> StakingValidatorsInteractor {
        CommonStakingValidatorsInteractor(input: io.input, output: io.output)
    }
}
