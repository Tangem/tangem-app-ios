//
//  SecurityOptionChangingMock.swift
//  Tangem
//
//  Created by Alexander Osokin on 01.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class SecurityOptionChangingMock: SecurityOptionChanging {
    var availableSecurityOptions: [SecurityModeOption] = []

    private var _currentSecurityOption: CurrentValueSubject<SecurityModeOption, Never> = .init(.longTap)

    var currentSecurityOption: SecurityModeOption {
        _currentSecurityOption.value
    }

    var currentSecurityOptionPublisher: AnyPublisher<SecurityModeOption, Never> {
        _currentSecurityOption.eraseToAnyPublisher()
    }

    func changeSecurityOption(_ option: SecurityModeOption, completion: @escaping (Result<Void, Error>) -> Void) {
        switch option {
        case .accessCode:
            _currentSecurityOption.value = .accessCode
        case .passCode:
            _currentSecurityOption.value = .passCode
        case .longTap:
            _currentSecurityOption.value = .longTap
        }

        completion(.success(()))
    }
}
