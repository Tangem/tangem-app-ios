//
//  GetPaymentAccountByCardMethod.swift
//  TangemVisa
//
//  Created by Andrew Son on 18/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct GetPaymentAccountByCardMethod: SmartContractMethod {
    let cardWalletAddress: String
    private let methodSignature = "paymentAccountByCard(address)"

    var prefix: String {
        SmartContractMethodPrefixCreator().createPrefixForMethod(with: methodSignature)
    }

    var data: Data {
        let prefixData = Data(hexString: prefix)
        let ownerData = Data(hexString: cardWalletAddress).leadingZeroPadding(toLength: 32)
        return prefixData + ownerData
    }
}
