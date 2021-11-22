//
//  SignAndReadTask.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class SignAndReadTask: CardSessionRunnable {
    let hashes: [Data]
    let walletPublicKey: Data
    let hdPath: DerivationPath?
    private var signCommand: SignHashesCommand? = nil
    
    init(hashes: [Data], walletPublicKey: Data, hdPath: DerivationPath?) {
        self.hashes = hashes
        self.walletPublicKey = walletPublicKey
        self.hdPath = hdPath
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<SignAndReadTaskResponse>) {
        signCommand = SignHashesCommand(hashes: hashes, walletPublicKey: walletPublicKey, hdPath: hdPath)
        signCommand!.run(in: session) { signResult in
            switch signResult {
            case .success(let signResponse):
                completion(.success(SignAndReadTaskResponse(signatures: signResponse.signatures, card: session.environment.card!)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension SignAndReadTask {
    struct SignAndReadTaskResponse {
        let signatures: [Data]
        let card: Card
    }
}
