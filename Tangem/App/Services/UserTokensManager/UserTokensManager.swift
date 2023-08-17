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
    var isInitialSyncPerformed: Bool { get }
    var initialSyncPublisher: AnyPublisher<Bool, Never> { get }
}

protocol UserTokensManager: UserTokensSyncService {
    var derivationManager: DerivationManager? { get }

    func deriveIfNeeded(completion: @escaping (Result<Void, TangemSdkError>) -> Void)

    func contains(_ tokenItem: TokenItem, derivationPath: DerivationPath?) -> Bool
    func getAllTokens(for blockchainNetwork: BlockchainNetwork) -> [Token]

    /// Update storage with derivation
    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void)
    /// Update storage without derivtion
    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], derivationPath: DerivationPath?)

    func updateUserTokens()

    func add(_ tokenItem: TokenItem, derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void)
    func add(_ tokenItems: [TokenItem], derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void)

    /// Add token and retrieve it's address
    func add(_ tokenItem: TokenItem, derivationPath: DerivationPath?) async throws -> String

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
