//
//  EVMSmartContractInteractor.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 17/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol EVMSmartContractInteractor {
    func ethCall<Request: SmartContractRequest>(request: Request) -> AnyPublisher<String, Error>
}
