//
//  OnrampProvidersCompactProviderViewData.swift
//  TangemApp
//
//  Created by Sergey Balashov on 31.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct OnrampProvidersCompactProviderViewData {
    let iconURL: URL?
    let paymentMethodName: String
    let providerName: String
    let badge: Badge?
    let action: () -> Void
}

extension OnrampProvidersCompactProviderViewData: Hashable, Identifiable {
    var id: Int { hashValue }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(iconURL)
        hasher.combine(paymentMethodName)
        hasher.combine(providerName)
        hasher.combine(badge)
    }
}

extension OnrampProvidersCompactProviderViewData {
    enum Badge: Hashable {
        case bestRate
    }
}
