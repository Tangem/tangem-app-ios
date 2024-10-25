//
//  CardanoUtil.swift
//  Tangem
//
//  Created by Sergey Balashov on 14.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct CardanoUtil {
    static let extendedPublicKeyCount = 128

    public init() {}

    /// Taken from here:
    /// https://github.com/trustwallet/wallet-core/blob/aa7475536e8c5b0383b1553073139b3498a9e35f/src/HDWallet.cpp#L163
    public func extendedDerivationPath(for derivationPath: DerivationPath) throws -> DerivationPath {
        var nodes = derivationPath.nodes
        guard nodes.count == 5 else {
            throw Errors.derivationPathIsShort
        }

        nodes[3] = .nonHardened(2)
        nodes[4] = .nonHardened(0)

        let extendedDerivationPath = DerivationPath(nodes: nodes)
        return extendedDerivationPath
    }

    /// Method for compute a extended public key
    /// - Parameters:
    ///   - publicKey: First `ExtendedPublicKey` with some derivation. For default `m/1852'/1815'/0'/0/0`
    ///   - extendedPublicKey: Second `ExtendedPublicKey` with the changed fourth and fifth node in the first derivation path. For default `m/1852'/1815'/0'/2/0`
    /// - Returns: The computed `PublicKey` is 128 bytes in size.
    func extendPublicKey(_ publicKey: ExtendedPublicKey, with extendedPublicKey: ExtendedPublicKey) -> Data {
        publicKey.publicKey + publicKey.chainCode + extendedPublicKey.publicKey + extendedPublicKey.chainCode
    }
}

extension CardanoUtil {
    enum Errors: Error {
        case derivationPathIsShort
    }
}
