//
//  SendWalletInfo.swift
//  Tangem
//
//  Created by Andrey Chukavin on 24.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct SendWalletInfo {
    let walletName: String
    let balance: String
    let tokenIconInfo: TokenIconInfo
    let cryptoCurrencyCode: String
    let fiatCurrencyCode: String
    let amountFractionDigits: Int
}
