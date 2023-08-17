//
//  FakeDerivationManager.swift
//  Tangem
//
//  Created by Andrew Son on 14/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class FakeDerivationManager: DerivationManager {
    var hasPendingDerivations: AnyPublisher<Bool, Never> {
        _pendingDerivationsCount.map { $0 > 0 }
            .eraseToAnyPublisher()
    }

    var pendingDerivationsCount: AnyPublisher<Int, Never> {
        _pendingDerivationsCount.eraseToAnyPublisher()
    }

    private let _pendingDerivationsCount: CurrentValueSubject<Int, Never> = .init(0)

    init(pendingDerivationsCount: Int = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self._pendingDerivationsCount.send(pendingDerivationsCount)
        }
    }

    func deriveKeys(cardInteractor: CardDerivable, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            completion(.success(()))
            self._pendingDerivationsCount.send(0)
        }
    }
}
