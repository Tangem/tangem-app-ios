//
//  TransactionListItem.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TransactionListItem: Hashable, Identifiable {
    var id: Int { hashValue }

    let header: String
    let items: [TransactionViewModel]
}
