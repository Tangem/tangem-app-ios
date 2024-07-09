//
//  DestinationAdditionalFieldType.swift
//  Tangem
//
//  Created by Sergey Balashov on 19.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum DestinationAdditionalFieldType {
    case notSupported
    case empty(type: SendAdditionalFields)
    case filled(type: SendAdditionalFields, value: String, params: TransactionParams)
}
