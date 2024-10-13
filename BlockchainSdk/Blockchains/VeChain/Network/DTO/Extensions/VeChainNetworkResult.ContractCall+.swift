//
//  VeChainNetworkResult.ContractCall+.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 17.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension VeChainNetworkResult.ContractCallPayload {
    func ensureNoError() throws {
        if let vmInvocationError = vmError, !vmInvocationError.isEmpty {
            throw ContractCallError.contractCallFailed
        }

        if reverted {
            throw ContractCallError.contractCallReverted
        }
    }
}

// MARK: - Auxiliary types

extension VeChainNetworkResult.ContractCallPayload {
    enum ContractCallError: Error {
        case contractCallFailed
        case contractCallReverted
    }
}
