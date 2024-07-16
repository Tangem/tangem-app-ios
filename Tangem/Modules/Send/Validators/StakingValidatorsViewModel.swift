//
//  StakingValidatorsViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.xw
//

import Combine
import TangemStaking

final class StakingValidatorsViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var validators: [ValidatorViewData] = []
    @Published var selectedValidator: String = ""

    // MARK: - Dependencies

    private let interactor: StakingValidatorsInteractor

    private let stakingValidatorViewMapper = StakingValidatorViewMapper()
    private var bag: Set<AnyCancellable> = []

    init(interactor: StakingValidatorsInteractor) {
        self.interactor = interactor

        bind()
    }

    func onAppear() {}
}

// MARK: - Private

private extension StakingValidatorsViewModel {
    func bind() {
        interactor
            .validatorsPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .map { viewModel, validators in
                // TODO: https://tangem.atlassian.net/browse/IOS-7105
                viewModel.selectedValidator = validators.first?.address ?? ""

                return validators.map {
                    viewModel.stakingValidatorViewMapper.mapToValidatorViewData(info: $0, detailsType: .checkmark)
                }
            }
            .assign(to: \.validators, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

extension StakingValidatorsViewModel {
    struct Input {
        let validators: [ValidatorInfo]
    }
}
