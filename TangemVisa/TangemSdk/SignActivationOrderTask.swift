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
    public let order: CardActivationOrder
    public let signedOrderByCard: Data
    public let cardAttestationSalt: Data
    public let signedOrderByWallet: Data
}

class SignActivationOrderTask: CardSessionRunnable {
    typealias CompletionHandler = CompletionResult<SignedActivationOrder>

    private let orderToSign: CardActivationOrder
    private let isTestnet: Bool

    init(orderToSign: CardActivationOrder, isTestnet: Bool = false) {
        self.orderToSign = orderToSign
        self.isTestnet = isTestnet
    }

    func run(in session: CardSession, completion: @escaping CompletionHandler) {
        signOrderWithCard(in: session, completion: completion)
    }

    private func signOrderWithCard(in session: CardSession, completion: @escaping CompletionHandler) {
        let task = AttestCardKeyCommand(challenge: orderToSign.dataToSignByCard)
        task.run(in: session) { result in
            switch result {
            case .success(let attestResponse):
                self.signOrderWithWallet(
                    in: session,
                    signedOrderByCard: attestResponse,
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func signOrderWithWallet(
        in session: CardSession,
        signedOrderByCard: AttestCardKeyResponse,
        completion: @escaping CompletionHandler
    ) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let visaUtilities = VisaUtilities(isTestnet: isTestnet)
        guard let derivationPath = visaUtilities.visaCardDerivationPath else {
            completion(.failure(.underlying(error: VisaActivationError.missingDerivationPath)))
            return
        }

        guard let wallet = card.wallets.first(where: { $0.curve == visaUtilities.mandatoryCurve }) else {
            completion(.failure(.underlying(error: VisaActivationError.missingWallet)))
            return
        }

        let signHashCommand = SignHashCommand(
            hash: orderToSign.dataToSignByWallet,
            walletPublicKey: wallet.publicKey,
            derivationPath: derivationPath
        )
        signHashCommand.run(in: session) { result in
            switch result {
            case .success(let signResponse):
                completion(.success(SignedActivationOrder(
                    cardSignedOrder: card,
                    order: self.orderToSign,
                    signedOrderByCard: signedOrderByCard.cardSignature,
                    cardAttestationSalt: signedOrderByCard.salt,
                    signedOrderByWallet: signResponse.signature
                )))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
