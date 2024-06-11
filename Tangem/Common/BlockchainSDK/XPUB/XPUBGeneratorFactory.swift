//
//  XPUBGeneratorFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 11.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct XPUBGeneratorFactory {
    private let cardInteractor: KeysDeriving

    init(cardInteractor: any KeysDeriving) {
        self.cardInteractor = cardInteractor
    }

    func makeXPUBGenerator(for blockchain: Blockchain, publicKey: Wallet.PublicKey) -> XPUBGenerator? {
        guard blockchain.curve == .secp256k1,
              let hdKey = publicKey.derivationType?.hdKey else {
            return nil
        }

        let childKey = makeChildKey(
            isBip44DerivationStyleXPUB: blockchain.isBip44DerivationStyleXPUB,
            derivationPath: hdKey.path,
            extendedPublicKey: hdKey.extendedPublicKey
        )

        let parentKey = CommonXPUBGenerator.Key(
            derivationPath: childKey.derivationPath.droppingLastNode(count: 1),
            extendedPublicKey: nil
        )

        return CommonXPUBGenerator(
            isTestnet: blockchain.isTestnet,
            seedKey: publicKey.seedKey,
            parentKey: parentKey,
            childKey: childKey,
            cardInteractor: cardInteractor
        )
    }

    private func makeChildKey(
        isBip44DerivationStyleXPUB: Bool,
        derivationPath: DerivationPath,
        extendedPublicKey: ExtendedPublicKey
    ) -> CommonXPUBGenerator.Key {
        guard isBip44DerivationStyleXPUB else {
            return CommonXPUBGenerator.Key(derivationPath: derivationPath, extendedPublicKey: extendedPublicKey)
        }

        let derivationPath = derivationPath.droppingLastNode(count: 2)
        return CommonXPUBGenerator.Key(derivationPath: derivationPath, extendedPublicKey: nil)
    }
}

// MARK: - DerivationPath+

private extension DerivationPath {
    func droppingLastNode(count: Int) -> DerivationPath {
        return DerivationPath(nodes: nodes.dropLast(count))
    }
}
