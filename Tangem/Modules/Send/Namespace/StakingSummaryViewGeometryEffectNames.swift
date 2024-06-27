//
//  StakingSummaryViewGeometryEffectNames.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - All names

struct SendGeometryEffectNames: SendAmountViewGeometryEffectNames {
    var walletName: String { SendViewNamespaceId.walletName.rawValue }
    var walletBalance: String { SendViewNamespaceId.walletBalance.rawValue }
    var amountContainer: String { SendViewNamespaceId.amountContainer.rawValue }
    var tokenIcon: String { SendViewNamespaceId.tokenIcon.rawValue }
    var amountCryptoText: String { SendViewNamespaceId.amountCryptoText.rawValue }
    var amountFiatText: String { SendViewNamespaceId.amountFiatText.rawValue }
}

// MARK: - Amount section

protocol SendAmountViewGeometryEffectNames {
    var walletName: String { get }
    var walletBalance: String { get }
    var amountContainer: String { get }
    var tokenIcon: String { get }
    var amountCryptoText: String { get }
    var amountFiatText: String { get }
}

// MARK: - Summary section

protocol SendSummaryViewGeometryEffectNames {
    var amountContainer: String { get }
    var tokenIcon: String { get }
    var amountCryptoText: String { get }
    var amountFiatText: String { get }
}
