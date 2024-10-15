//
//  GetTotalBalanceMethod.swift
//  TangemVisa
//
//  Created by Andrew Son on 18/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct GetTotalBalanceMethod: SmartContractMethod {
    let paymentAccountAddress: String
    private let methodSignature = "balanceOf(address)"

    var prefix: String { SmartContractMethodPrefixCreator().createPrefixForMethod(with: methodSignature) }

    var data: Data {
        let prefixData = Data(hexString: prefix)
        let ownerData = Data(hexString: paymentAccountAddress).leadingZeroPadding(toLength: 32)
        return prefixData + ownerData
    }
}
