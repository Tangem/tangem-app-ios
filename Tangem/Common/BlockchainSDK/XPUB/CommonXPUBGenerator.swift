//
//  CommonXPUBGenerator.swift
//  Tangem
//
//  Created by Alexander Osokin on 11.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class CommonXPUBGenerator {
    private let isTestnet: Bool
    private let seedKey: Data
    private var parentKey: Key
    private var childKey: Key
    private let cardInteractor: KeysDeriving

    init(
        isTestnet: Bool,
        seedKey: Data,
        parentKey: CommonXPUBGenerator.Key,
        childKey: CommonXPUBGenerator.Key,
        cardInteractor: any KeysDeriving
    ) {
        self.isTestnet = isTestnet
        self.seedKey = seedKey
        self.parentKey = parentKey
        self.childKey = childKey
        self.cardInteractor = cardInteractor
    }

    private func prepareKeys() async throws {
        let pendingDerivations = getPendingDerivations()
        guard !pendingDerivations.isEmpty else {
            return
        }

        let derivedKeys = try await deriveKeys(for: pendingDerivations)

        if childKey.extendedPublicKey == nil {
            guard let extendedPublicKey = derivedKeys[childKey.derivationPath] else {
                throw Error.failedToGenerateXPUB
            }

            childKey.extendedPublicKey = extendedPublicKey
        }

        if parentKey.extendedPublicKey == nil {
            guard let extendedPublicKey = derivedKeys[parentKey.derivationPath] else {
                throw Error.failedToGenerateXPUB
            }

            parentKey.extendedPublicKey = extendedPublicKey
        }
    }

    private func getPendingDerivations() -> [DerivationPath] {
        var pendingDerivations: [DerivationPath] = []

        if childKey.extendedPublicKey == nil {
            pendingDerivations.append(childKey.derivationPath)
        }

        if parentKey.extendedPublicKey == nil {
            pendingDerivations.append(parentKey.derivationPath)
        }

        return pendingDerivations
    }

    private func deriveKeys(for paths: [DerivationPath]) async throws -> DerivedKeys {
        let result = try await cardInteractor.deriveKeys(derivations: [seedKey: paths])
        return result[seedKey] ?? [:]
    }

    private func makeExtendedKey() throws -> ExtendedPublicKey {
        guard let publicKey = childKey.extendedPublicKey?.publicKey,
              let chainCode = childKey.extendedPublicKey?.chainCode,
              let lastChildNode = childKey.derivationPath.nodes.last,
              let parentPublicKey = parentKey.extendedPublicKey?.publicKey else {
            throw Error.failedToGenerateXPUB
        }

        let depth = childKey.derivationPath.nodes.count
        let childNumber = lastChildNode.index
        let parentFingerprint = parentPublicKey.sha256Ripemd160.prefix(4)

        let key = try ExtendedPublicKey(
            publicKey: publicKey,
            chainCode: chainCode,
            depth: depth,
            parentFingerprint: parentFingerprint,
            childNumber: childNumber
        )

        return key
    }
}

// MARK: - XPUBGenerator+

extension CommonXPUBGenerator: XPUBGenerator {
    func generateXPUB() async throws -> String {
        try await prepareKeys()
        let extendedPublicKey = try makeExtendedKey()
        let xpub = try extendedPublicKey.serialize(for: isTestnet ? .testnet : .mainnet)
        return xpub
    }
}

extension CommonXPUBGenerator {
    struct Key {
        let derivationPath: DerivationPath
        var extendedPublicKey: ExtendedPublicKey?

        init(derivationPath: DerivationPath, extendedPublicKey: ExtendedPublicKey?) {
            self.derivationPath = derivationPath
            self.extendedPublicKey = extendedPublicKey
        }
    }
}

extension CommonXPUBGenerator {
    enum Error: String, LocalizedError {
        case failedToGenerateXPUB

        var errorDescription: String? {
            rawValue
        }
    }
}
