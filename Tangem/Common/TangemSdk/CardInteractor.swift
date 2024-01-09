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
    private var cancellable: AnyCancellable?
    private var input: Input

    internal init(cardInfo: CardInfo) {
        input = .cardInfo(cardInfo)
    }

    internal init(cardId: String) {
        input = .cardId(cardId)
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
        let tangemSdk = input.makeTangemSdk()

        tangemSdk.startSession(
            with: task,
            filter: input.cardIdFilter,
            initialMessage: initialMessage
        ) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(task) {}
            withExtendedLifetime(tangemSdk) {}
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
        let tangemSdk = input.makeTangemSdk()

        tangemSdk.startSession(
            with: task,
            filter: input.cardKitFilter
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                AppLog.shared.error(error, params: [.action: .deriveKeys])
                completion(.failure(error))
            }

            withExtendedLifetime(task) {}
            withExtendedLifetime(tangemSdk) {}
        }
    }
}

private extension CardInteractor {
    enum Input {
        case cardInfo(CardInfo)
        case cardId(String)

        var cardInfo: CardInfo? {
            switch self {
            case .cardInfo(let cardInfo):
                return cardInfo
            case .cardId:
                return nil
            }
        }

        var cardKitFilter: SessionFilter {
            switch self {
            case .cardInfo(let cardInfo):
                let config = UserWalletConfigFactory(cardInfo).makeConfig()
                return config.cardSessionFilter
            case .cardId:
                return cardIdFilter
            }
        }

        var cardIdFilter: SessionFilter {
            switch self {
            case .cardInfo(let cardInfo):
                return .cardId(cardInfo.card.cardId)
            case .cardId(let cardId):
                return .cardId(cardId)
            }
        }

        func makeTangemSdk() -> TangemSdk {
            switch self {
            case .cardInfo(let cardInfo):
                let config = UserWalletConfigFactory(cardInfo).makeConfig()
                let tangemSdk = config.makeTangemSdk()
                return tangemSdk
            case .cardId:
                let tangemSdk = TangemSdkDefaultFactory().makeTangemSdk()
                return tangemSdk
            }
        }
    }
}
