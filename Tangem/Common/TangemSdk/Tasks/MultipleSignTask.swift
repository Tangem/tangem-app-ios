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
    private let dataToSign: [SignData]
    private let seedKey: Data

    public init(dataToSign: [SignData], seedKey: Data) {
        self.dataToSign = dataToSign
        self.seedKey = seedKey
    }

    deinit {
        Log.debug("MultipleSignTask deinit")
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<[MultipleSignTaskResponse]>) {
        let completionQueue = OperationQueue.current?.underlyingQueue ?? .main

        TangemFoundation.runTask(in: self) { task in
            let result: Result<[MultipleSignTaskResponse], TangemSdkError>
            do {
                let signed = try await task.dataToSign.asyncMap { data in
                    let signResponse = try await task.runSign(
                        derivationPath: data.derivationPath,
                        hash: data.hash,
                        session: session
                    )
                    guard let signature = signResponse.signatures.first else {
                        throw TangemSdkError.signHashesNotAvailable
                    }
                    return MultipleSignTaskResponse(
                        signature: signature,
                        card: signResponse.card,
                        publicKey: data.publicKey
                    )
                }
                result = .success(signed)
            } catch {
                result = .failure(error.toTangemSdkError())
            }

            completionQueue.async {
                completion(result)
            }
        }
    }

    private func runSign(
        derivationPath: DerivationPath,
        hash: Data,
        session: CardSession
    ) async throws -> SignAndReadTask.SignAndReadTaskResponse {
        let signCommand = SignAndReadTask(
            hashes: [hash],
            walletPublicKey: seedKey,
            pairWalletPublicKey: nil,
            derivationPath: derivationPath
        )

        return try await withCheckedThrowingContinuation { continuation in
            signCommand.run(in: session) { result in
                switch result {
                case .success(let signResponse):
                    continuation.resume(returning: signResponse)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension MultipleSignTask {
    struct MultipleSignTaskResponse {
        let signature: Data
        let card: Card
        let publicKey: Data
    }
}
