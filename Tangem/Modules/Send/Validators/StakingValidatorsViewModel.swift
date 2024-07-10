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

    private let percentFormatter = PercentFormatter()
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
                validators.map { viewModel.mapToValidatorViewData(info: $0) }
            }
            .assign(to: \.validators, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func mapToValidatorViewData(info: ValidatorInfo) -> ValidatorViewData {
        ValidatorViewData(
            id: info.address,
            imageURL: info.iconURL,
            name: info.name,
            aprFormatted: info.apr.map { percentFormatter.format($0, option: .staking) },
            detailsType: .checked
        )
    }
}

extension StakingValidatorsViewModel {
    struct Input {
        let validators: [ValidatorInfo]
    }
}
