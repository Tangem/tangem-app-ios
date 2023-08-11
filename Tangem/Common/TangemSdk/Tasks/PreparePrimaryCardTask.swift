//
//  PreparePrimaryCardTask.swift
//  Tangem
//
//  Created by Andrew Son on 27.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import TangemSdk
import BlockchainSdk

class PreparePrimaryCardTask: CardSessionRunnable {
    var shouldAskForAccessCode: Bool { false }

    private let curves: [EllipticCurve]
    private let mnemonic: Mnemonic?
    private var commandBag: (any CardSessionRunnable)?

    init(curves: [EllipticCurve], mnemonic: Mnemonic?) {
        self.curves = curves
        self.mnemonic = mnemonic
    }

    deinit {
        AppLog.shared.debug("PreparePrimaryCardTask deinit")
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        if card.settings.isHDWalletAllowed {
            let config = UserWalletConfigFactory(CardInfo(card: CardDTO(card: card), walletData: .none, name: "")).makeConfig()
            let blockchainNetworks = config.defaultBlockchains.map { $0.blockchainNetwork }

            let derivations: [EllipticCurve: [DerivationPath]] = blockchainNetworks.reduce(into: [:]) { result, network in
                if let path = network.derivationPath {
                    result[network.blockchain.curve, default: []].append(path)
                }
            }

            var sdkConfig = session.environment.config
            sdkConfig.defaultDerivationPaths = derivations
            session.updateConfig(with: sdkConfig)
        }

        createMultiWallet(in: session, completion: completion)
    }

    private func createMultiWallet(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let existingCurves = card.wallets.map { $0.curve }
        let curvesToCreate = curves.filter { !existingCurves.contains($0) }

        let command = CreateMultiWalletTask(curves: curvesToCreate, mnemonic: mnemonic)
        commandBag = command
        command.run(in: session) { result in
            switch result {
            case .success:
                self.readPrimaryCardIfNeeded(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func readPrimaryCardIfNeeded(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard card.firmwareVersion >= .backupAvailable, card.settings.isBackupAllowed else {
            completion(.success(.init(card: card, primaryCard: nil)))
            return
        }

        let command = StartPrimaryCardLinkingTask()
        commandBag = command
        command.run(in: session) { result in
            switch result {
            case .success(let primaryCard):
                guard let card = session.environment.card else {
                    completion(.failure(.missingPreflightRead))
                    return
                }

                let response = PreparePrimaryCardTaskResponse(card: card, primaryCard: primaryCard)
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension PreparePrimaryCardTask {
    struct PreparePrimaryCardTaskResponse {
        let card: Card
        let primaryCard: PrimaryCard?
    }
}
