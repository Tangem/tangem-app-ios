//
//  SwapAvailabilityManager.swift
//  Tangem
//
//  Created by Andrew Son on 26/09/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

protocol SwapAvailabilityProvider {
    var availabilityDidChangePublisher: AnyPublisher<Void, Never> { get }

    func swapState(for tokenItem: TokenItem) -> TokenItemExpressState
    func onrampState(for tokenItem: TokenItem) -> TokenItemExpressState

    func canSwap(tokenItem: TokenItem) -> Bool
    func onrampSwap(tokenItem: TokenItem) -> Bool

    func updateExpressAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String)
}

private struct SwapAvailabilityProviderKey: InjectionKey {
    static var currentValue: SwapAvailabilityProvider = CommonSwapAvailabilityProvider()
}

extension InjectedValues {
    var swapAvailabilityProvider: SwapAvailabilityProvider {
        get { Self[SwapAvailabilityProviderKey.self] }
        set { Self[SwapAvailabilityProviderKey.self] = newValue }
    }
}
