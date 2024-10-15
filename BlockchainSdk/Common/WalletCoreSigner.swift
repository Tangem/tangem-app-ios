//
//  WalletCoreSigner.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 03.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//
import Combine

import TangemSdk
import WalletCore

// This class implements a bridge between Tangem SDK and TrustWallet's WalletCore library
// It is implemented with several restrictions in mind, mainly lack of compatibility between
// C++ and Swift exceptions and the way async/await functions work
class WalletCoreSigner: Signer {
    let publicKey: Data
    
    private let signQueue = DispatchQueue(label: "com.signer.queue", qos: .userInitiated)
    
    private(set) var error: Error?
    
    private let sdkSigner: TransactionSigner
    private let walletPublicKey: Wallet.PublicKey
    private let curve: EllipticCurve
    
    private var signSubscription: AnyCancellable?
    
    init(sdkSigner: TransactionSigner, blockchainKey: Data, walletPublicKey: Wallet.PublicKey, curve: EllipticCurve) {
        self.sdkSigner = sdkSigner
        self.publicKey = blockchainKey
        self.walletPublicKey = walletPublicKey
        self.curve = curve
    }
    
    func sign(_ data: Data) -> Data {
        sign([data]).first ?? Data()
    }
    
    func sign(_ data: [Data]) -> [Data] {
        // We need this function to freeze the current thread until the TangemSDK operation is complete.
        // We need this because async/await concepts are not compatible between C++ and Swift.
        // Because this function freezes the current thread make sure to call WalletCore's AnySigner from a non-GUI thread.
        
        var signedData: [Data] = []
        
        let operation = BlockOperation { [weak self] in
            guard let self else { return }
            
            let group = DispatchGroup()
            group.enter()
            
            self.signSubscription = self.sdkSigner.sign(hashes: data, walletPublicKey: self.walletPublicKey)
                .tryMap { signatures in
                    if case .secp256k1 = self.curve {
                        return try self.unmarshal(signatures, for: data)
                    } else {
                        return signatures
                    }
                }
                .sink { completion in
                    if case .failure(let error) = completion {
                        self.error = error
                    }
                    
                    group.leave()
                } receiveValue: { data in
                    signedData = data
                }
            
            group.wait()
        }
        
        signQueue.sync {
            operation.start()
            operation.waitUntilFinished()
        }
        
        return signedData
    }
    
    private func unmarshal(_ signatures: [Data], for data: [Data]) throws -> [Data] {
        try signatures
            .enumerated()
            .map { (index, signature) in
                try self.unmarshal(signature, for: data[index])
            }
    }
    
    private func unmarshal(_ signature: Data, for data: Data) throws -> Data {
        let secpSignature = try Secp256k1Signature(with: signature)
        return try secpSignature.unmarshal(with: publicKey, hash: data).data
    }
}
