//
//  PendingExpressTransaction.swift
//  Tangem
//
//  Created by Andrew Son on 04/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PendingExpressTransaction: Equatable {
    let transactionRecord: ExpressPendingTransactionRecord
    let statuses: [PendingExpressTransactionStatus]
}

extension PendingExpressTransaction: Identifiable {
    var id: String {
        transactionRecord.id
    }
}
