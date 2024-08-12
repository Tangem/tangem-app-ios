//
//  AllowanceProvider.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol AllowanceProvider {
    func isPermissionRequired(request: ExpressManagerSwappingPairRequest, for spender: String) async throws -> Bool
    func makeApproveData(spender: String, amount: Decimal) throws -> Data
}

public enum AllowanceProviderError: LocalizedError {
    case ethereumNetworkProviderNotFound
    case ethereumTransactionProcessorNotFound
    case approveTransactionInProgress
}
