//
//  AnalyticsContextData.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct AnalyticsContextData {
    let productType: Analytics.ProductType
    let batchId: String
    let firmware: String
    let baseCurrency: String?
    var userWalletId: UserWalletId?

    var analyticsParams: [Analytics.ParameterKey: String] {
        var params: [Analytics.ParameterKey: String] = [
            .productType: productType.rawValue,
            .batch: batchId,
            .firmware: firmware,
            .basicCurrency: baseCurrency ?? Analytics.ParameterValue.multicurrency.rawValue,
        ]

        // You need to send it only if the parameter exists. The default value is not needed.
        if let userWalletId {
            params[.userWalletId] = userWalletId.stringValue

            if AppSettings.shared.userWalletIdsWithRing.contains(userWalletId.stringValue) {
                params[.productType] = Analytics.ProductType.ring.rawValue
            }
        }

        return params
    }
}

extension AnalyticsContextData {
    init(card: CardDTO, productType: Analytics.ProductType, embeddedEntry: StorageEntry?, userWalletId: UserWalletId?) {
        self.productType = productType
        batchId = card.batchId
        firmware = card.firmwareVersion.stringValue
        baseCurrency = embeddedEntry?.tokens.first?.symbol ?? embeddedEntry?.blockchainNetwork.blockchain.currencySymbol
        self.userWalletId = userWalletId
    }
}
