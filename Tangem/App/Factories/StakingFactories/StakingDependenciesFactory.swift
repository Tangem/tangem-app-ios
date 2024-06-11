//
//  StakingDependenciesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

class StakingDependenciesFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func makeStakingAPIProvider() -> StakingAPIProvider {
        TangemStakingFactory().makeStakingAPIProvider(
            credential: StakingAPICredential(apiKey: keysManager.stakeKitKey),
            configuration: .defaultConfiguration
        )
    }
}
