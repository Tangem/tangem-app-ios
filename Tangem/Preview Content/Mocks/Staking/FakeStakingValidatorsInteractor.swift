//
//  FakeStakingValidatorsInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

struct FakeStakingValidatorsInteractor: StakingValidatorsInteractor {
    let _validators = CurrentValueSubject<[ValidatorInfo], Never>([
        .init(
            address: UUID().uuidString,
            name: "InfStones",
            iconURL: URL(string: "https://assets.stakek.it/validators/infstones.png")!,
            apr: 0.008
        ),
        .init(
            address: UUID().uuidString,
            name: "Aconcagua",
            iconURL: URL(string: "ttps://assets.stakek.it/validators/aconcagua.png")!,
            apr: 0.023
        ),
    ])

    var validatorsPublisher: AnyPublisher<[ValidatorInfo], Never> {
        _validators.eraseToAnyPublisher()
    }
}
