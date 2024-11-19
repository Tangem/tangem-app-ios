//
//  ExpressExchangeDataDecoder.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 20.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressExchangeDataDecoder {
    func decode<T: Decodable>(txDetailsJson: String, signature: String) throws -> T
}
