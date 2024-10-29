//
//  SolanaWalletConnectSigner.swift
//  Tangem
//
//  Created by GuitarKitty on 15.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SolanaWalletConnectSigner: WalletConnectSigner {
    let signer: TangemSigner

    func sign(data: Data, using walletModel: WalletModel) async throws -> String {
        let pubKey = walletModel.wallet.publicKey
        return try await signer.sign(hash: data, walletPublicKey: pubKey)
            .tryMap { response -> String in
                response.base58EncodedString
            }
            .eraseToAnyPublisher()
            .async()
    }
}
