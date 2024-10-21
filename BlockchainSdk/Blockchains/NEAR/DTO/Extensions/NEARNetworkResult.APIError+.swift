//
//  NEARNetworkResult.APIError+.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension NEARNetworkResult.APIError {
    var isUnknownAccount: Bool {
        return name == .handlerError && cause.name == .unknownAccount
    }

    var isUnknownTransaction: Bool {
        return name == .handlerError && cause.name == .unknownTransaction
    }

    var isInvalidTransaction: Bool {
        return name == .handlerError && cause.name == .invalidTransaction
    }
}
