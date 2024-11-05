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
    private weak var input: OnrampInput?
    private weak var output: OnrampOutput?

    init(
        input: OnrampInput,
        output: OnrampOutput
    ) {
        self.input = input
        self.output = output
    }
}

// MARK: - OnrampInteractor

extension CommonOnrampInteractor: OnrampInteractor {
    var isValidPublisher: AnyPublisher<Bool, Never> {
        guard let input else {
            assertionFailure("OnrampInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.isValidPublisher
    }
}
