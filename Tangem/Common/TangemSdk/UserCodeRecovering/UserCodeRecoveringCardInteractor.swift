//
//  UserCodeRecoveringCardInteractor.swift
//  Tangem
//
//  Created by Alexander Osokin on 15.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class UserCodeRecoveringCardInteractor {
    private let tangemSdk: TangemSdk
    private let cardId: String
    private var _isUserCodeRecoveryAllowed: CurrentValueSubject<Bool, Never>

    init(with cardInfo: CardInfo) {
        cardId = cardInfo.card.cardId
        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        tangemSdk = config.makeTangemSdk()
        _isUserCodeRecoveryAllowed = .init(cardInfo.card.userSettings.isUserCodeRecoveryAllowed)
    }
}

// MARK: - UserCodeRecovering

extension UserCodeRecoveringCardInteractor: UserCodeRecovering {
    var isUserCodeRecoveryAllowed: Bool {
        _isUserCodeRecoveryAllowed.value
    }

    var isUserCodeRecoveryAllowedPublisher: AnyPublisher<Bool, Never> {
        _isUserCodeRecoveryAllowed.eraseToAnyPublisher()
    }

    func toggleUserCodeRecoveryAllowed(completion: @escaping (Result<Bool, TangemSdkError>) -> Void) {
        let newValue = !_isUserCodeRecoveryAllowed.value

        tangemSdk.setUserCodeRecoveryAllowed(newValue, cardId: cardId) { [weak self] result in
            switch result {
            case .success:
                self?._isUserCodeRecoveryAllowed.send(newValue)
                completion(.success(newValue))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
