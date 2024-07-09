//
//  SendBaseInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 27.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendBaseInteractor {
    var isLoading: AnyPublisher<Bool, Never> { get }

    func send() -> AnyPublisher<SendTransactionSentResult, Never>
}

class CommonSendBaseInteractor {
    private let input: SendBaseInput
    private let output: SendBaseOutput

    init(
        input: SendBaseInput,
        output: SendBaseOutput
    ) {
        self.input = input
        self.output = output
    }
}

extension CommonSendBaseInteractor: SendBaseInteractor {
    var isLoading: AnyPublisher<Bool, Never> {
        input.isLoading
    }

    func send() -> AnyPublisher<SendTransactionSentResult, Never> {
        output.sendTransaction()
    }
}
