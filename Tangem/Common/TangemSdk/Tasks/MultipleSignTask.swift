//
//  MultipleSignTask.swift
//  TangemApp
//
//  Created by Dmitry Fedorov on 17.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Foundation
import TangemSdk
import BlockchainSdk

class MultipleSignTask: CardSessionRunnable {
    private let dataToSign: [Wallet.PublicKey.HDKey: Data]
    private let seedKey: Data
    
    /// Derive multiple wallet  public keys according to BIP32 (Private parent key → public child key).
    /// Warning: Only `secp256k1` and `ed25519` (BIP32-Ed25519 scheme) curves supported
    /// - Parameters:
    ///   - walletPublicKey: Seed public key.
    ///   - derivationPaths: Multiple derivation paths. Repeated items will be ignored.
    public init(dataToSign: [Wallet.PublicKey.HDKey: Data], seedKey: Data) {
        self.dataToSign = dataToSign
        self.seedKey = seedKey
    }
    
    deinit {
        Log.debug("DeriveWalletPublicKeysTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<[Data]>) {
        runDerivation(at: 0, keys: [:], in: session, completion: completion)
    }
    
    private func runDerivation(at index: Int, keys: DerivedKeys, in session: CardSession, completion: @escaping CompletionResult<[Data]>) {
        guard index < derivationPaths.count else {
            completion(.success(keys))
            return
        }
        let path = derivationPaths[index]
        let task = DeriveWalletPublicKeyTask(walletPublicKey: walletPublicKey, derivationPath: path)
        task.run(in: session) { result in
            var keys = keys

            switch result {
            case .success(let key):
                keys[path] = key
            case .failure(let error):
                switch error {
                case .nonHardenedDerivationNotSupported, .walletNotFound, .unsupportedCurve:
                    // continue derivation
                    Log.error(error)
                default:
                    if keys.keys.isEmpty {
                        completion(.failure(error))
                    } else {
                        Log.error(error)
                        // return partial response
                        completion(.success(keys))
                    }
                    return
                }
            }

            self.runDerivation(at: index + 1, keys: keys, in: session, completion: completion)
        }
    }
}
