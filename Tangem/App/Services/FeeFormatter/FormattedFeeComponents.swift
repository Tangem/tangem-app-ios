//
//  FormattedFeeComponents.swift
//  Tangem
//
//  Created by Andrey Chukavin on 15.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct FormattedFeeComponents {
    let cryptoFee: String
    let fiatFee: String?
}

extension FormattedFeeComponents: Hashable {}
