//
//  StakingRepository.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol StakingRepository {
    var enabledYieldsPublisher: AnyPublisher<[YieldInfo], Never> { get }

    func updateEnabledYields(withReload: Bool)

    func getYield(item: StakingTokenItem) -> YieldInfo?
}
