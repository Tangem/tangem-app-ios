//
//  PendingOnrampTransaction.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 20.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PendingOnrampTransaction: Equatable {
    let transactionRecord: OnrampPendingTransactionRecord
    let statuses: [PendingOnrampTransactionStatus]
}
