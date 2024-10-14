//
//  GetTokenInfoMethod.swift
//  TangemVisa
//
//  Created by Andrew Son on 14/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct GetTokenInfoMethod: SmartContractMethod {
    let infoType: InfoType

    var prefix: String {
        SmartContractMethodPrefixCreator().createPrefixForMethod(with: infoType.rawValue)
    }

    var data: Data {
        let prefixData = Data(hexString: prefix)
        return prefixData.trailingZeroPadding(toLength: 32)
    }
}

extension GetTokenInfoMethod {
    enum InfoType: String {
        case contractAddress = "paymentToken()"
        case name = "name()"
        case symbol = "symbol()"
        case decimals = "decimals()"
    }
}
