//
//  ExpressTransactionStatus.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressTransactionStatus: String, Codable {
    case processing
    case done
    case failed
    case refunded
    case verificationRequired
}
