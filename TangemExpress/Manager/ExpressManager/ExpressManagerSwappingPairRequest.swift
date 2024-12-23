//
//  ExpressManagerSwappingPairRequest.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressManagerSwappingPairRequest {
    public let pair: ExpressManagerSwappingPair
    public let amount: Decimal
    public let feeOption: ExpressFeeOption
}
