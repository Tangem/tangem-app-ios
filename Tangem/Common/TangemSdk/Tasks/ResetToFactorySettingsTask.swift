//
//  ResetToFactorySettingsTask.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class ResetToFactorySettingsTask: CardSessionRunnable {
    var shouldAskForAccessCode: Bool { false }

    private var didReset: Bool = false

    func run(in session: CardSession, completion: @escaping CompletionResult<Bool>) {
        deteleWallets(in: session, completion: completion)
    }

    private func deteleWallets(in session: CardSession, completion: @escaping CompletionResult<Bool>) {
        guard let wallet = session.environment.card?.wallets.last else {
            resetBackup(in: session, completion: completion)
            return
        }

        PurgeWalletCommand(publicKey: wallet.publicKey).run(in: session) { result in
            switch result {
            case .success:
                self.didReset = true
                self.deteleWallets(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func resetBackup(in session: CardSession, completion: @escaping CompletionResult<Bool>) {
        guard let backupStatus = session.environment.card?.backupStatus,
              backupStatus != .noBackup else {
            completion(.success(didReset))
            return
        }

        ResetBackupCommand().run(in: session) { result in
            switch result {
            case .success:
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
