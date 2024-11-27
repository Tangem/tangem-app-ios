//
//  SwapAvailabilityManager.swift
//  Tangem
//
//  Created by Andrew Son on 26/09/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

protocol ExpressAvailabilityProvider {
    var availabilityDidChangePublisher: AnyPublisher<Void, Never> { get }
    var expressAvailabilityUpdateState: AnyPublisher<ExpressAvailabilityUpdateState, Never> { get }

    func swapState(for tokenItem: TokenItem) -> TokenItemExpressState
    func onrampState(for tokenItem: TokenItem) -> TokenItemExpressState

    func canSwap(tokenItem: TokenItem) -> Bool
    func canOnramp(tokenItem: TokenItem) -> Bool

    func updateExpressAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String)
}

private struct ExpressAvailabilityProviderKey: InjectionKey {
    static var currentValue: ExpressAvailabilityProvider = CommonExpressAvailabilityProvider()
}

extension InjectedValues {
    var expressAvailabilityProvider: ExpressAvailabilityProvider {
        get { Self[ExpressAvailabilityProviderKey.self] }
        set { Self[ExpressAvailabilityProviderKey.self] = newValue }
    }
}
