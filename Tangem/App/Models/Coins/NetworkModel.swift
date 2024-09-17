//
//  Network.swift
//  Tangem
//
//  Created by skibinalexander on 03.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct NetworkModel: Codable {
    let networkId: String
    let contractAddress: String?
    let decimalCount: Int?
}
