//
//  UserTokensManager.swift
//  Tangem
//
//  Created by Alexander Osokin on 26.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk

protocol UserTokensSyncService {
    var initialized: Bool { get }
    var initializedPublisher: AnyPublisher<Bool, Never> { get }
}

protocol UserTokensManager: UserTokensReordering {
    var derivationManager: DerivationManager? { get }

    func deriveIfNeeded(completion: @escaping (Result<Void, TangemSdkError>) -> Void)

    func contains(_ tokenItem: TokenItem) -> Bool
    func getAllTokens(for blockchainNetwork: BlockchainNetwork) -> [Token]

    /// Update storage with derivation
    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], completion: @escaping (Result<Void, TangemSdkError>) -> Void)
    /// Update storage without derivtion
    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) throws

    /// Check condition for adding token
    func addTokenItemPrecondition(_ tokenItem: TokenItem) throws
    func add(_ tokenItem: TokenItem, completion: @escaping (Result<Void, TangemSdkError>) -> Void)
    func add(_ tokenItems: [TokenItem], completion: @escaping (Result<Void, TangemSdkError>) -> Void)

    /// Add token and retrieve it's address
    func add(_ tokenItem: TokenItem) async throws -> String

    func canRemove(_ tokenItem: TokenItem) -> Bool
    func remove(_ tokenItem: TokenItem)

    func sync(completion: @escaping () -> Void)
}

extension UserTokensManager {
    func add(_ tokenItems: [TokenItem]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            add(tokenItems) { result in
                continuation.resume(with: result)
            }
        }
    }

    func add(_ tokenItem: TokenItem, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        add([tokenItem], completion: completion)
    }
}
