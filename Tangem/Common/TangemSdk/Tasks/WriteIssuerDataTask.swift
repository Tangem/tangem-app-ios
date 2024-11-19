//
//  WriteIssuerDataTask.swift
//  Tangem
//
//  Created by Andrew Son on 18/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class WriteIssuerDataTask: CardSessionRunnable {
    var message: Message? { Message(header: Localization.twinsRecreateTitleCreatingWallet) }

    private let pairPubKey: Data
    private let keys: KeyPair

    private var signedPubKeyHash: Data!
    private var command: WriteIssuerDataCommand?

    init(pairPubKey: Data, keys: KeyPair) {
        self.pairPubKey = pairPubKey
        self.keys = keys
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard let publicKey = card.wallets.first?.publicKey else {
            completion(.failure(.cardError))
            return
        }

        let sign = SignHashCommand(hash: pairPubKey.sha256(), walletPublicKey: publicKey)
        sign.run(in: session) { result in
            switch result {
            case .success(let response):
                self.signedPubKeyHash = response.signature
                self.readIssuerCounter(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func readIssuerCounter(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        let readCommand = ReadIssuerDataCommand()
        readCommand.run(in: session) { result in
            switch result {
            case .success(let response):
                self.writeIssuerData(in: session, counter: response.issuerDataCounter, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func writeIssuerData(in session: CardSession, counter: Int?, completion: @escaping CompletionResult<SuccessResponse>) {
        guard let cardId = session.environment.card?.cardId else {
            completion(.failure(.cardError))
            return
        }

        let dataToSign = pairPubKey + signedPubKeyHash
        let newCounter = (counter ?? 0) + 1

        guard let hashes = try? FileHashHelper.prepareHash(for: cardId, fileData: dataToSign, fileCounter: newCounter, privateKey: keys.privateKey),
              let signature = hashes.finalizingSignature
        else {
            completion(.failure(.signHashesNotAvailable))
            return
        }

        command = WriteIssuerDataCommand(
            issuerData: dataToSign,
            issuerDataSignature: signature,
            issuerDataCounter: newCounter,
            issuerPublicKey: keys.publicKey
        )
        command!.run(in: session) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
