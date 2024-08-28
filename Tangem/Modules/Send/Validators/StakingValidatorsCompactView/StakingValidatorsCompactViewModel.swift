//
//  StakingValidatorsCompactViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

class StakingValidatorsCompactViewModel: ObservableObject, Identifiable {
    // Use the estimated size as initial value
    @Published var viewSize: CGSize = .init(width: 361, height: 88)
    @Published var selectedValidator: ValidatorCompactViewData?

    private weak var input: StakingValidatorsInput?

    private let percentFormatter = PercentFormatter()
    private var bag: Set<AnyCancellable> = []

    init(input: StakingValidatorsInput) {
        self.input = input

        bind(input: input)
    }

    func bind(input: StakingValidatorsInput) {
        input
            .selectedValidatorPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, validator in
                viewModel.mapToValidatorCompactViewData(validator: validator)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.selectedValidator, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func mapToValidatorCompactViewData(validator: ValidatorInfo) -> ValidatorCompactViewData {
        ValidatorCompactViewData(
            address: validator.address,
            name: validator.name,
            imageURL: validator.iconURL,
            aprFormatted: validator.apr.map {
                "\(Localization.stakingDetailsApr) \(percentFormatter.format($0, option: .staking))"
            }
        )
    }
}
