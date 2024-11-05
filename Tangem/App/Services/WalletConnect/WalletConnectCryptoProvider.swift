//
//  WalletConnectCryptoProvider.swift
//  Tangem
//
//  Created by skibinalexander on 07.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift
import ReownWalletKit
import TangemSdk

struct WalletConnectCryptoProvider: CryptoProvider {
    public func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
        let extendedSignature = Secp256k1Signature.Extended(r: Data(signature.r), s: Data(signature.s), v: Data(signature.v))
        let secp256k1Key = try Secp256k1Key(with: extendedSignature, message: message)
        return try secp256k1Key.compress()
    }

    public func keccak256(_ data: Data) -> Data {
        return data.sha3(.keccak256)
    }
}
