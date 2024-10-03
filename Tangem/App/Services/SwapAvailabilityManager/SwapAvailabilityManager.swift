//
//  SwapAvailabilityManager.swift
//  Tangem
//
//  Created by Andrew Son on 26/09/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

typealias SwapAvailabilityManager = SwapAvailabilityProvider & SwapAvailabilityController

protocol SwapAvailabilityController {
    func loadSwapAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String)
}

protocol SwapAvailabilityProvider {
    var tokenItemsAvailableToSwapPublisher: AnyPublisher<[TokenItem: TokenItemSwapState], Never> { get }
    func swapState(for tokenItem: TokenItem) -> TokenItemSwapState
    func canSwap(tokenItem: TokenItem) -> Bool
}

private struct SwapAvailabilityManagerKey: InjectionKey {
    static var currentValue: SwapAvailabilityManager = CommonSwapAvailabilityManager()
}

extension InjectedValues {
    var swapAvailabilityController: SwapAvailabilityController {
        manager
    }

    var swapAvailabilityProvider: SwapAvailabilityProvider {
        manager
    }

    private var manager: SwapAvailabilityManager {
        get { Self[SwapAvailabilityManagerKey.self] }
        set { Self[SwapAvailabilityManagerKey.self] = newValue }
    }
}
