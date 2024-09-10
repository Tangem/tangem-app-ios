//
//  TokenMarketsDetailsRoutable.swift
//  Tangem
//
//  Created by Andrew Son on 24/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenMarketsDetailsRoutable: AnyObject, MarketsPortfolioContainerRoutable {
    func openURL(_ url: URL)
    func openTokenSelector(with model: TokenMarketsDetailsModel, walletDataProvider: MarketsWalletDataProvider)
    func closeModule()
}
