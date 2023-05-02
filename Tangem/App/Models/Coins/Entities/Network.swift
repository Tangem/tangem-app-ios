//
//  Network.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.04.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension CoinsResponse {
    struct Network: Codable {
        public let networkId: String
        public let contractAddress: String?
        public let decimalCount: Int?
        public let exchangeable: Bool
    }
}
