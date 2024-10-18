//
//  OnrampInteractor.swift
//  TangemApp
//
//  Created by Sergey Balashov on 18.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampInteractor: AnyObject {
    var isValidPublisher: AnyPublisher<Bool, Never> { get }
}

class CommonOnrampInteractor {
    weak var input: OnrampInput?
    weak var output: OnrampOutput?

    private let onrampManager: OnrampManager
    private let isValid: CurrentValueSubject<Bool, Never> = .init(false)

    init(
        input: OnrampInput?,
        output: OnrampOutput?,
        onrampManager: OnrampManager
    ) {
        self.input = input
        self.output = output
        self.onrampManager = onrampManager
    }
}

// MARK: - OnrampInteractor

extension CommonOnrampInteractor: OnrampInteractor {
    var isValidPublisher: AnyPublisher<Bool, Never> {
        isValid.eraseToAnyPublisher()
    }
}
