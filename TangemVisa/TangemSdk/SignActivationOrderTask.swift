//
//  SignActivationOrderTask.swift
//  TangemVisa
//
//  Created by Andrew Son on 18.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SignedActivationOrder {
    let order: Data
    let signedOrderByCard: Data
    let signedOrderByWallet: Data
}

class SignActivationOrderTask: CardSessionRunnable {
    typealias CompletionHandler = CompletionResult<SignedActivationOrder>

    private let orderToSign: Data

    init(orderToSign: Data) {
        self.orderToSign = orderToSign
    }

    func run(in session: CardSession, completion: @escaping CompletionHandler) {
        completion(.failure(.underlying(error: VisaActivationError.notImplemented)))
        // TODO: IOS-8572
    }

    private func signOrderWithCard(in session: CardSession, orderToSign: Data, completion: @escaping CompletionHandler) {
        // TODO: IOS-8572
    }

    private func deriveWalletKey(in session: CardSession, completion: @escaping CompletionHandler) {
        // TODO: IOS-8572
    }

    private func signOrderWithWallet(
        in session: CardSession,
        dataToSign: Data,
        signedOrderByCard: AttestCardKeyResponse,
        completion: @escaping CompletionHandler
    ) {
        // TODO: IOS-8572
    }
}
