//
//  SolanaError+.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 31.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

extension SolanaError: @retroactive LocalizedError {
    public var errorDescription: String? {
        // TODO: add localization
        switch self {
        case .unauthorized:
            return "unauthorized"
        case .notFoundProgramAddress:
            return "notFoundProgramAddress"
        case .invalidRequest(let reason):
            return "invalidRequest (\(reason ?? ""))"
        case .invalidResponse(let error):
            return "invalidResponse (\(error.code ?? -1))"
        case .socket:
            return "socket"
        case .couldNotRetriveAccountInfo:
            return "couldNotRetrieveAccountInfo"
        case .other(let reason):
            return "other (\(reason))"
        case .nullValue:
            return "nullValue"
        case .couldNotRetriveBalance:
            return "couldNotRetrieveBalance"
        case .blockHashNotFound:
            return "blockHashNotFound"
        case .invalidPublicKey:
            return "invalidPublicKey"
        case .invalidMNemonic:
            return "invalidMnemonic"
        }
    }
}
