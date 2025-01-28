//
//  PreparePrimaryCardTask.swift
//  Tangem
//
//  Created by Andrew Son on 27.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class PreparePrimaryCardTask: CardSessionRunnable {
    var shouldAskForAccessCode: Bool { false }

    private let curves: [EllipticCurve]
    private let shouldReset: Bool
    private let mnemonic: Mnemonic?
    private let passphrase: String?
    private var commandBag: (any CardSessionRunnable)?

    private var initializedCard: Card?
    private var primaryCard: PrimaryCard?

    init(curves: [EllipticCurve], mnemonic: Mnemonic?, passphrase: String?, shouldReset: Bool) {
        self.curves = curves
        self.shouldReset = shouldReset
        self.mnemonic = mnemonic
        self.passphrase = passphrase
    }

    deinit {
        AppLog.debug(self)
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
                result[network.blockchain.curve, default: []].append(contentsOf: network.derivationPaths())
            }

            var sdkConfig = session.environment.config
            sdkConfig.defaultDerivationPaths = derivations
            session.updateConfig(with: sdkConfig)
        }

        if card.wallets.isEmpty {
            createMultiWallet(in: session, completion: completion)
        } else if shouldReset {
            resetCard(in: session, completion: completion)
        } else {
            completion(.failure(.walletAlreadyCreated))
        }
    }

    private func createMultiWallet(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        let command = CreateMultiWalletTask(curves: curves, mnemonic: mnemonic, passphrase: passphrase)
        commandBag = command
        command.run(in: session) { result in
            switch result {
            case .success:
                // save the card with derived wallets
                self.initializedCard = session.environment.card
                self.checkIfAllWalletsCreated(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func checkIfAllWalletsCreated(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard card.firmwareVersion >= .multiwalletAvailable else {
            complete(completion)
            return
        }

        let command = ReadWalletsListCommand()
        commandBag = command
        command.run(in: session) { result in
            switch result {
            case .success(let response):
                // We can use createWalletCurves for validation here because of the new setup
                let validator = CurvesValidator(expectedCurves: self.curves)

                if validator.validate(response.wallets.map { $0.curve }) {
                    self.readPrimaryCardIfNeeded(in: session, completion: completion)
                } else {
                    completion(.failure(.walletAlreadyCreated))
                }
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

        let command = StartPrimaryCardLinkingCommand()
        commandBag = command
        command.run(in: session) { result in
            switch result {
            case .success(let primaryCard):
                self.primaryCard = primaryCard
                self.complete(completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func resetCard(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        let command = ResetToFactorySettingsTask()
        commandBag = command
        command.run(in: session) { result in
            switch result {
            case .success:
                self.createMultiWallet(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func complete(_ completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        guard let card = initializedCard else {
            completion(.failure(.unknownError))
            return
        }

        let response = PreparePrimaryCardTaskResponse(card: card, primaryCard: primaryCard)
        completion(.success(response))
    }
}

extension PreparePrimaryCardTask {
    struct PreparePrimaryCardTaskResponse {
        let card: Card
        let primaryCard: PrimaryCard?
    }
}
