//
//  KeysManager.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol KeysManager {
    var appsFlyer: AppsFlyerConfig { get }
    var moonPayKeys: MoonPayKeys { get }
    var mercuryoWidgetId: String { get }
    var mercuryoSecret: String { get }
    var blockchainConfig: BlockchainSdkConfig { get }
    var shopifyShop: ShopifyShop { get }
    var zendesk: ZendeskConfig { get }
    var infuraProjectId: String { get }
    var swapReferrerAccount: SwapReferrerAccount? { get }
    var utorgSID: String { get }
}

private struct KeysManagerKey: InjectionKey {
    static var currentValue: KeysManager = try! CommonKeysManager()
}

extension InjectedValues {
    var keysManager: KeysManager {
        get { Self[KeysManagerKey.self] }
        set { Self[KeysManagerKey.self] = newValue }
    }
}
