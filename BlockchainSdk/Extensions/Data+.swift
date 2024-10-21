//
//  Data+.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk
import class WalletCore.DataVector
import Sodium

extension Data {
    var bytes: Array<UInt8> {
        return Array(self)
    }

    public func leadingZeroPadding(toLength newLength: Int) -> Data {
        guard count < newLength else { return self }

        let prefix = Data(repeating: UInt8(0), count: newLength - count)
        return prefix + self
    }

    public func trailingZeroPadding(toLength newLength: Int) -> Data {
        guard count < newLength else { return self }

        let suffix = Data(repeating: UInt8(0), count: newLength - count)
        return self + suffix
    }

    func validateAsEdKey() throws {
        _ = try Curve25519.Signing.PublicKey(rawRepresentation: self)
    }

    func validateAsSecp256k1Key() throws {
        _ = try Secp256k1Key(with: self)
    }

    func asDataVector() -> DataVector {
        return DataVector(data: self)
    }

    func hashBlake2b(key: Data, outputLength: Int) -> Data? {
        guard let hash = Sodium().genericHash.hash(
            message: bytes,
            key: key.bytes,
            outputLength: outputLength) else {
            return nil
        }

        return Data(hash)
    }

    func hashBlake2b(outputLength: Int) -> Data? {
        guard let hash = Sodium().genericHash.hash(
            message: bytes,
            key: nil,
            outputLength: outputLength) else {
            return nil
        }

        return Data(hash)
    }
    
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}
