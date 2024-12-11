//
//  VisaCustomerWalletApproveTask.swift
//  TangemApp
//
//  Created by Andrew Son on 06.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemVisa

class VisaCustomerWalletApproveTask: CardSessionRunnable {
    typealias TaskResult = CompletionResult<SignHashResponse>
    private let targetAddress: String
    private let approveData: Data

    private let visaUtilities = VisaUtilities(isTestnet: false)
    private let pubKeySearchUtility = VisaWalletPublicKeyUtility(isTestnet: false)

    init(
        targetAddress: String,
        approveData: Data
    ) {
        self.targetAddress = targetAddress
        self.approveData = approveData
    }

    deinit {
        print("Deinit VisaCustomerWalletApproveTask")
    }

    func run(in session: CardSession, completion: @escaping TaskResult) {
        guard
            let card = session.environment.card,
            !visaUtilities.batchId.contains(card.batchId)
        else {
            completion(.failure(.underlying(error: "Can't use Visa card for approve")))
            return
        }

        if card.settings.isHDWalletAllowed {
            proceedApprove(card: card, in: session, completion: completion)
        } else {
            proceedApproveWithLegacyCard(card: card, in: session, completion: completion)
        }
    }
}

private extension VisaCustomerWalletApproveTask {
    func proceedApprove(card: Card, in session: CardSession, completion: @escaping TaskResult) {
        let cardDTO = CardDTO(card: card)
        let config = UserWalletConfigFactory(CardInfo(card: cardDTO, walletData: .none, name: "")).makeConfig()

        guard let derivationStyle = config.derivationStyle else {
            proceedApproveWithLegacyCard(card: card, in: session, completion: completion)
            return
        }

        guard let derivationPath = visaUtilities.visaDefaultDerivationPath(style: derivationStyle) else {
            completion(.failure(.underlying(error: "Failed to generate derivation path with provided derivation style")))
            return
        }

        let targetCurve = visaUtilities.visaBlockchain.curve
        guard let wallet = card.wallets.first(where: { $0.curve == targetCurve }) else {
            completion(.failure(.walletNotFound))
            return
        }

        let derivationTask = DeriveWalletPublicKeyTask(walletPublicKey: wallet.publicKey, derivationPath: derivationPath)
        derivationTask.run(in: session) { result in
            switch result {
            case .success:
                self.signApproveData(
                    targetWalletPublicKey: wallet.publicKey,
                    derivationPath: derivationPath,
                    in: session,
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func proceedApproveWithLegacyCard(card: Card, in session: CardSession, completion: @escaping TaskResult) {
        do {
            let searchUtility = VisaWalletPublicKeyUtility(isTestnet: false)
            let publicKey = try searchUtility.findKeyWithoutDerivation(targetAddress: targetAddress, on: card)
            signApproveData(targetWalletPublicKey: publicKey, derivationPath: nil, in: session, completion: completion)
        } catch {
            completion(.failure(.underlying(error: error)))
        }
    }

    func signApproveData(
        targetWalletPublicKey: Data,
        derivationPath: DerivationPath?,
        in session: CardSession,
        completion: @escaping TaskResult
    ) {
        let signTask = SignHashCommand(
            hash: approveData,
            walletPublicKey: targetWalletPublicKey,
            derivationPath: derivationPath
        )

        signTask.run(in: session) { result in
            switch result {
            case .success(let hashResponse):
                self.scanCard(hashResponse: hashResponse, in: session, completion: completion)
            case .failure(let sdkError):
                completion(.failure(sdkError))
            }
        }
    }

    func scanCard(hashResponse: SignHashResponse, in session: CardSession, completion: @escaping TaskResult) {
        let scanTask = ScanTask()

        scanTask.run(in: session) { result in
            switch result {
            case .success:
                completion(.success(hashResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
