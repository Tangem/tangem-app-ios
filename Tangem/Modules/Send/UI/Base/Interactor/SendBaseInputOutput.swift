//
//  SendBaseInputOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendBaseInput: AnyObject {
    var actionInProcessing: AnyPublisher<Bool, Never> { get }
}

protocol SendBaseOutput: AnyObject {
    func performAction() async throws -> SendTransactionDispatcherResult
}
