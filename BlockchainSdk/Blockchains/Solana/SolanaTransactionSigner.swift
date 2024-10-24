//
//  SolanaTransactionSigner.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 18.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Solana_Swift

class SolanaTransactionSigner: Signer {
    var publicKey: PublicKey {
        PublicKey(data: walletPublicKey.blockchainKey)!
    }
    
    let transactionSigner: TransactionSigner
    let walletPublicKey: Wallet.PublicKey
    
    var subscriptions: Set<AnyCancellable> = []
    
    init(transactionSigner: TransactionSigner, walletPublicKey: Wallet.PublicKey) {
        self.transactionSigner = transactionSigner
        self.walletPublicKey = walletPublicKey
    }
    
    func sign(message: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        transactionSigner.sign(hash: message, walletPublicKey: walletPublicKey)
            .sink { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .finished:
                    break
                }
            } receiveValue: { data in
                completion(.success(data))
            }
            .store(in: &subscriptions)
    }
}

