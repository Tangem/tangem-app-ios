//
//  ExpressTransaction.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressTransaction {
    public let status: ExpressTransactionStatus
    public let externalStatus: String
    public let externalTxUrl: String
    public let errorCode: Int
}
