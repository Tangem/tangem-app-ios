//
//  CardInteractor.swift
//  Tangem
//
//  Created by Alexander Osokin on 27.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

class CardInteractor {
    private let tangemSdk: TangemSdk
    private var cardId: String?
    private var cancellable: AnyCancellable?

    internal init(tangemSdk: TangemSdk, cardId: String?) {
        self.tangemSdk = tangemSdk
        self.cardId = cardId
    }
}

// MARK: - CardResettable

protocol CardResettable: AnyObject {
    func resetCard(completion: @escaping (Result<Void, TangemSdkError>) -> Void)
}

extension CardInteractor: CardResettable {
    func resetCard(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        let initialMessage = Message(header: nil, body: Localization.initialMessagePurgeWalletBody)
        let task = ResetToFactorySettingsTask()

        tangemSdk.startSession(
            with: task,
            cardId: cardId,
            initialMessage: initialMessage
        ) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(task) {}
        }
    }
}

// MARK: - CardDerivable

protocol CardDerivable: AnyObject {
    func deriveKeys(derivations: [Data: [DerivationPath]], completion: @escaping (Result<DerivationResult, TangemSdkError>) -> Void)
}

typealias DerivationResult = DeriveMultipleWalletPublicKeysTask.Response

extension CardInteractor: CardDerivable {
    func deriveKeys(derivations: [Data: [DerivationPath]], completion: @escaping (Result<DerivationResult, TangemSdkError>) -> Void) {
        let task = DeriveMultipleWalletPublicKeysTask(derivations)

        tangemSdk.startSession(
            with: task,
            cardId: cardId
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                AppLog.shared.error(error, params: [.action: .deriveKeys])
                completion(.failure(error))
            }

            withExtendedLifetime(task) {}
        }
    }
}
