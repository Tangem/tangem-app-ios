//
//  MarketsTokensNetworkRoutable.swift
//  Tangem
//
//  Created by skibinalexander on 21.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsTokensNetworkRoutable: AnyObject {
    func openWalletSelector(with provider: MarketsWalletDataProvider)
    func dissmis()
}
