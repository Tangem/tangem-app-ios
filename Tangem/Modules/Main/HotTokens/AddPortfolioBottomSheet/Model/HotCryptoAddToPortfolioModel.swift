//
//  HotCryptoAddToPortfolioModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 16.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct HotCryptoAddToPortfolioModel: Identifiable {
    let id = UUID()
    let token: HotCryptoDataItem
    let walletName: String
}
