//
//  ExpressTransactionType.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressTransactionType: String, Codable {
    case send
    case swap
}
