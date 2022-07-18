//
//  KeysManager.swift
//  Tangem
//
//  Created by Andrew Son on 07/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class CommonKeysManager {
    private let keys: Keys

    init() {
        do {
            self.keys = try KeysParser().keys
        } catch {
            print("Failed to parse keys", error)
            self.keys = .empty
        }
    }
}

extension CommonKeysManager: KeysManager {
    var appsFlyerDevKey: String {
        keys.appsFlyerDevKey
    }

    var moonPayKeys: MoonPayKeys {
        MoonPayKeys(apiKey: keys.moonPayApiKey, secretApiKey: keys.moonPayApiSecretKey)
    }

    var mercuryoWidgetId: String {
        keys.mercuryoWidgetId
    }

    var mercuryoSecret: String {
        keys.mercuryoSecret
    }

    var blockchainConfig: BlockchainSdkConfig {
        BlockchainSdkConfig(blockchairApiKey: keys.blockchairApiKey,
                            blockcypherTokens: keys.blockcypherTokens,
                            infuraProjectId: keys.infuraProjectId,
                            tronGridApiKey: keys.tronGridApiKey)
    }

    var shopifyShop: ShopifyShop {
        keys.shopifyShop
    }

    var zendesk: ZendeskConfig {
        keys.zendesk
    }

    var amplitudeApiKey: String {
        keys.amplitudeApiKey
    }
}

extension CommonKeysManager {
    struct Keys: Decodable {
        let moonPayApiKey: String
        let moonPayApiSecretKey: String
        let mercuryoWidgetId: String
        let mercuryoSecret: String
        let blockchairApiKey: String
        let blockcypherTokens: [String]
        let infuraProjectId: String
        let appsFlyerDevKey: String
        let amplitudeApiKey: String
        let tronGridApiKey: String
        let shopifyShop: ShopifyShop
        let zendesk: ZendeskConfig

        fileprivate static var empty: Keys {
            .init(moonPayApiKey: "",
                  moonPayApiSecretKey: "",
                  mercuryoWidgetId: "",
                  mercuryoSecret: "",
                  blockchairApiKey: "",
                  blockcypherTokens: [],
                  infuraProjectId: "",
                  appsFlyerDevKey: "",
                  amplitudeApiKey: "",
                  tronGridApiKey: "",
                  shopifyShop: .init(domain: "",
                                     storefrontApiKey: "",
                                     merchantID: ""),
                  zendesk: .init(zendeskApiKey: "",
                                 zendeskAppId: "",
                                 zendeskClientId: "",
                                 zendeskUrl: "")
            )
        }
    }
}
