//
//  SwappingApprovedDataModel.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 08.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct SwappingApprovedDataModel {
    public let data: Data
    public let tokenAddress: String

    /// The value which send for approve in WEI
    public let value: Decimal
}
