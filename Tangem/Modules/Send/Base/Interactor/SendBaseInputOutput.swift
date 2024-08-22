//
//  SendBaseInputOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendBaseInput: AnyObject {
    var isFeeIncluded: Bool { get }

    var actionInProcessing: AnyPublisher<Bool, Never> { get }
    var additionalActionProcessing: AnyPublisher<Bool, Never> { get }
}

extension SendBaseInput {
    var additionalActionProcessing: AnyPublisher<Bool, Never> {
        .just(output: false)
    }
}

protocol SendBaseOutput: AnyObject {
    func sendTransaction() async throws -> SendTransactionDispatcherResult
    func sendAdditionalTransaction() async throws -> SendTransactionDispatcherResult
}

extension SendBaseOutput {
    func sendAdditionalTransaction() async throws -> SendTransactionDispatcherResult {
        throw SendTransactionDispatcherResult.Error.transactionNotFound
    }
}
