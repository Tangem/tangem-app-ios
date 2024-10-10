//
//  JSONEncoder+.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 28.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension JSONEncoder {
    static var withSnakeCaseStrategy: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
