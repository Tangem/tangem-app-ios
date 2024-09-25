//
//  TransactionStatus.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 16.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum TransactionStatus: String, Hashable {
    case created
    case waitingForSignature
    case broadcasted
    case pending
    case confirmed
    case failed
    case skipped
}
