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

    private let isValid: CurrentValueSubject<Bool, Never> = .init(true)

    init(input: OnrampInput, output: OnrampOutput) {
        self.input = input
        self.output = output

        bind()
    }

    private func bind() {
        // TODO: Lisen input aka OnrampModel
    }
}

// MARK: - OnrampInteractor

extension CommonOnrampInteractor: OnrampInteractor {
    var isValidPublisher: AnyPublisher<Bool, Never> {
        isValid.eraseToAnyPublisher()
    }
}
