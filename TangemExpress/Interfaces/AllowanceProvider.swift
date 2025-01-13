//
//  AllowanceProvider.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressAllowanceProvider {
    func allowanceState(request: ExpressManagerSwappingPairRequest, spender: String) async throws -> AllowanceState
}

public enum AllowanceState: Hashable {
    case permissionRequired(ApproveTransactionData)
    case approveTransactionInProgress
    case enoughAllowance
}

public struct ApproveTransactionData: Hashable {
    public let txData: Data
    public let spender: String
    public let toContractAddress: String
    public let fee: Fee

    public init(txData: Data, spender: String, toContractAddress: String, fee: Fee) {
        self.txData = txData
        self.spender = spender
        self.toContractAddress = toContractAddress
        self.fee = fee
    }
}
