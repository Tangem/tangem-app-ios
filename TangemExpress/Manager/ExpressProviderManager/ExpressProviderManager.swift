//
//  ExpressProviderManager.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 11.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressProviderManager: Actor {
    func getState() -> ExpressProviderManagerState

    func update(request: ExpressManagerSwappingPairRequest) async
    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData
}
