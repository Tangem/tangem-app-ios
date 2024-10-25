//
//  SignatureUtils.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 03.09.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum SignatureUtils {
    /// Unmarshals a signature using the provided original signature, public key, and hash.
    /// This function is essential for certain blockchains that require signature unmarshalling to correctly
    /// reconstruct the signature for verification.
    ///
    /// - Parameters:
    ///   - originalSignature: The original `Data` object representing the signature to be unmarshalled.
    ///   - publicKey: The `Data` object representing the public key associated with the signature.
    ///   - hash: The `Data` object representing the hash of the message or transaction.
    /// - Returns: A `Data` object containing the unmarshalled signature, which includes the `r` and `s` values
    ///   concatenated with the adjusted recovery ID.
    /// - Throws: `WalletError.failedToBuildTx` if the unmarshalling process fails due to an invalid recovery ID.
    ///
    /// - Important: For certain blockchains, especially those using the Secp256k1 curve, signature unmarshalling
    ///   is required to correctly reconstruct the signature from the original data. This process involves verifying
    ///   and adjusting the recovery ID, which is essential for ensuring the signature is valid and can be used for
    ///   transaction verification. The function checks the length of the recovery ID and adjusts it within valid bounds
    ///   before concatenating it with the `r` and `s` components of the signature.

    static func unmarshalledSignature(from originalSignature: Data, publicKey: Data, hash: Data) throws -> Data {
        let signature = try Secp256k1Signature(with: originalSignature)
        let unmarshalledSignature = try signature.unmarshal(with: publicKey, hash: hash)

        guard unmarshalledSignature.v.count == Constants.recoveryIdLength else {
            throw WalletError.failedToBuildTx
        }

        let recoveryId = unmarshalledSignature.v[0] - Constants.recoveryIdDiff

        guard recoveryId >= Constants.recoveryIdLowerBound, recoveryId <= Constants.recoveryIdUpperBound else {
            throw WalletError.failedToBuildTx
        }

        return unmarshalledSignature.r + unmarshalledSignature.s + Data(recoveryId)
    }
}

private extension SignatureUtils {
    enum Constants {
        static let recoveryIdLength = 1
        static let recoveryIdDiff: UInt8 = 27
        static let recoveryIdLowerBound: UInt8 = 0
        static let recoveryIdUpperBound: UInt8 = 3
    }
}
