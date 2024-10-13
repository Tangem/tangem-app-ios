//
//  PolygonScanAPIError.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 20.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum PolygonScanAPIError: Error {
    case maxRateLimitReached
    case endOfTransactionHistoryReached
    case unknown
}
