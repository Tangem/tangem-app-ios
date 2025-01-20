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
import TangemFoundation

class MultipleSignTask: CardSessionRunnable {
    private let dataToSign: [Wallet.PublicKey.HDKey: Data]
    private let seedKey: Data

    public init(dataToSign: [Wallet.PublicKey.HDKey: Data], seedKey: Data) {
        self.dataToSign = dataToSign
        self.seedKey = seedKey
    }
    
    deinit {
        Log.debug("MultipleSignTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<[Data]>) {
        let queue = OperationQueue.current?.underlyingQueue ?? .main
        TangemFoundation.runTask(in: self) { task in
            let result: Result<[Data], TangemSdkError>
            do {
                let signed = try await task.dataToSign.asyncMap { hdKey, hash in
                    try await task.runSign(hdKey: hdKey, hash: hash, session: session)
                }
                result = .success(signed.flatMap { $0 })
            } catch {
                result = .failure(error.toTangemSdkError())
            }
            queue.async {
                completion(result)
            }
        }
    }
    
    private func runSign(hdKey: Wallet.PublicKey.HDKey, hash: Data, session: CardSession) async throws -> [Data] {
        let signCommand = SignAndReadTask(
            hashes: [hash],
            walletPublicKey: seedKey,
            pairWalletPublicKey: nil,
            derivationPath: hdKey.path
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            signCommand.run(in: session) { result in
                switch result {
                case .success(let hashes):
                    continuation.resume(returning: hashes.signatures)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
