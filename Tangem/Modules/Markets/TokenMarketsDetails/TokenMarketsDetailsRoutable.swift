//
//  TokenMarketsDetailsRoutable.swift
//  Tangem
//
//  Created by Andrew Son on 24/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenMarketsDetailsRoutable: AnyObject {
    func openTokenSelector(dataSource: MarketsDataSource, coinId: String, tokenItems: [TokenItem])
}
