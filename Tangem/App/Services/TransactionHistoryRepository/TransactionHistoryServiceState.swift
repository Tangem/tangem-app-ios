//
//  TransactionHistoryServiceState.swift
//  Tangem
//
//  Created by Sergey Balashov on 15.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum TransactionHistoryServiceState {
    case initial
    case loading
    case failedToLoad(Error)
    case loaded
}
