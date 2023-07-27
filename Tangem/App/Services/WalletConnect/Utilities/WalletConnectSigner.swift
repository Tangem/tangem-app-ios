//
//  WalletConnectSigner.swift
//  Tangem
//
//  Created by Andrew Son on 30/01/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSdk

protocol WalletConnectSigner {
    func sign(data: Data, using walletModel: WalletModel) async throws -> String
}

struct CommonWalletConnectSigner: WalletConnectSigner {
    let signer: TangemSigner

    func sign(data: Data, using walletModel: WalletModel) async throws -> String {
        let pubKey = walletModel.wallet.publicKey
        return try await signer.sign(hash: data, walletPublicKey: pubKey)
            .tryMap { response -> String in
                if let unmarshalledSig = try? Secp256k1Signature(with: response).unmarshal(
                    with: pubKey.blockchainKey,
                    hash: data
                ) {
                    let strSig = "0x" + unmarshalledSig.r.hexString + unmarshalledSig.s.hexString +
                        unmarshalledSig.v.hexString
                    return strSig
                } else {
                    throw WalletConnectServiceError.signFailed
                }
            }
            .eraseToAnyPublisher()
            .async()
    }
}
