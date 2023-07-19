//
//  UserTokensManager.swift
//  Tangem
//
//  Created by Alexander Osokin on 26.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

protocol UserTokensManager {
    func contains(_ tokenItem: TokenItem, derivationPath: DerivationPath?) -> Bool
    func getAllTokens(for blockchainNetwork: BlockchainNetwork) -> [Token]

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void)

    func add(_ tokenItem: TokenItem, derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void)
    func add(_ tokenItems: [TokenItem], derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void)

    // Add token and retrieve it's address
    func add(_ tokenItem: TokenItem, derivationPath: DerivationPath?) async throws -> String
    func add(_ tokenItems: [TokenItem], derivationPath: DerivationPath?) async throws

    func canRemove(_ tokenItem: TokenItem, derivationPath: DerivationPath?) -> Bool
    func remove(_ tokenItem: TokenItem, derivationPath: DerivationPath?)
}

extension UserTokensManager {
    func add(_ tokenItems: [TokenItem], derivationPath: DerivationPath?) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            add(tokenItems, derivationPath: derivationPath) { result in
                continuation.resume(with: result)
            }
        }
    }

    func add(_ tokenItem: TokenItem, derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        add([tokenItem], derivationPath: derivationPath, completion: completion)
    }
}
