//
//  ExpressRepository.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 11.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public protocol ExpressRepository {
    func updatePairs(for wallet: ExpressWallet) async throws

    func providers() async throws -> [ExpressProvider]
    func getAvailableProviders(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider.Id]

    func getPairs(from wallet: ExpressWallet) async -> [ExpressPair]
    func getPairs(to wallet: ExpressWallet) async -> [ExpressPair]
}
