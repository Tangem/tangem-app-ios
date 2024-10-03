//
//  UserCodeRecoveringMock.swift
//  Tangem
//
//  Created by Andrew Son on 07/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class UserCodeRecoveringMock: UserCodeRecovering {
    var isUserCodeRecoveryAllowedPublisher: AnyPublisher<Bool, Never> { _isUserCodeRecoveryAllowed.eraseToAnyPublisher() }
    var isUserCodeRecoveryAllowed: Bool { _isUserCodeRecoveryAllowed.value }

    private var shouldShowError = false

    private var _isUserCodeRecoveryAllowed: CurrentValueSubject<Bool, Never> = .init(true)

    func toggleUserCodeRecoveryAllowed(completion: @escaping (Result<Bool, TangemSdkError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.shouldShowError.toggle()
            if self.shouldShowError {
                completion(.failure(.underlying(error: "Can't update access code recovery settings")))
            } else {
                self._isUserCodeRecoveryAllowed.value.toggle()
                completion(.success(self._isUserCodeRecoveryAllowed.value))
            }
        }
    }
}
