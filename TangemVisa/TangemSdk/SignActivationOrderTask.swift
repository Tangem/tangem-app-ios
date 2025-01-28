//
//  SignActivationOrderTask.swift
//  TangemVisa
//
//  Created by Andrew Son on 18.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct SignedActivationOrder {
    public let cardSignedOrder: Card
    public let order: VisaCardAcceptanceOrderInfo
    public let signedOrderByWallet: Data
}

class SignActivationOrderTask: CardSessionRunnable {
    typealias CompletionHandler = CompletionResult<SignedActivationOrder>

    private let orderToSign: VisaCardAcceptanceOrderInfo
    private let isTestnet: Bool
    private let visaUtilities: VisaUtilities

    init(orderToSign: VisaCardAcceptanceOrderInfo, isTestnet: Bool = false) {
        self.orderToSign = orderToSign
        self.isTestnet = isTestnet
        visaUtilities = VisaUtilities(isTestnet: isTestnet)
    }

    func run(in session: CardSession, completion: @escaping CompletionHandler) {
        deriveKey(in: session, completion: completion)
    }

    private func deriveKey(in session: CardSession, completion: @escaping CompletionHandler) {
        guard
            let wallet = session.environment.card?.wallets.first(where: { $0.curve == visaUtilities.mandatoryCurve })
        else {
            completion(.failure(.underlying(error: VisaActivationError.missingWallet)))
            return
        }

        guard let derivationPath = visaUtilities.visaDefaultDerivationPath else {
            completion(.failure(.underlying(error: VisaActivationError.missingDerivationPath)))
            return
        }

        let derivationTask = DeriveWalletPublicKeyTask(walletPublicKey: wallet.publicKey, derivationPath: derivationPath)
        derivationTask.run(in: session) { result in
            switch result {
            case .success:
                self.signOrderWithWallet(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func signOrderWithWallet(
        in session: CardSession,
        completion: @escaping CompletionHandler
    ) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard let derivationPath = visaUtilities.visaDefaultDerivationPath else {
            completion(.failure(.underlying(error: VisaActivationError.missingDerivationPath)))
            return
        }

        guard
            let wallet = card.wallets.first(where: { $0.curve == visaUtilities.mandatoryCurve }),
            wallet.derivedKeys[derivationPath] != nil
        else {
            completion(.failure(.underlying(error: VisaActivationError.missingWallet)))
            return
        }

        let signHashCommand = SignHashCommand(
            hash: orderToSign.hashToSignByWallet,
            walletPublicKey: wallet.publicKey,
            derivationPath: derivationPath
        )
        signHashCommand.run(in: session) { result in
            switch result {
            case .success(let signResponse):
                completion(.success(SignedActivationOrder(
                    cardSignedOrder: card,
                    order: self.orderToSign,
                    signedOrderByWallet: signResponse.signature
                )))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
