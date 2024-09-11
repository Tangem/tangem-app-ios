//
//  StakingValidatorsCompactViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class StakingValidatorsCompactViewModel: ObservableObject, Identifiable {
    // Use the estimated size as initial value
    @Published var viewSize: CGSize = .init(width: 361, height: 88)
    @Published var selectedValidatorData: ValidatorViewData?
    private weak var input: StakingValidatorsInput?

    private var bag: Set<AnyCancellable> = []

    init(input: StakingValidatorsInput) {
        self.input = input

        bind(input: input)
    }

    func bind(input: StakingValidatorsInput) {
        let stakingValidatorViewMapper = StakingValidatorViewMapper()

        input.selectedValidatorPublisher
            .map { validator in
                stakingValidatorViewMapper.mapToValidatorViewData(info: validator, detailsType: .chevron())
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.selectedValidatorData, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
