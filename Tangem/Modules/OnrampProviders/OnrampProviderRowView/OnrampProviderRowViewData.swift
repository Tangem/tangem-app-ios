//
//  OnrampProviderRowViewData.swift
//  TangemApp
//
//  Created by Sergey Balashov on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct OnrampProviderRowViewData {
    let id: String
    let name: String
    let iconURL: URL?
    let formattedAmount: String
    let badge: Badge
    let isSelected: Bool

    let action: () -> Void
}

extension OnrampProviderRowViewData {
    enum Badge: Hashable {
        case bestRate
        case percent(String, signType: ChangeSignType)
    }
}

extension OnrampProviderRowViewData: Identifiable, Hashable {
    static func == (lhs: OnrampProviderRowViewData, rhs: OnrampProviderRowViewData) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(iconURL)
        hasher.combine(formattedAmount)
        hasher.combine(badge)
        hasher.combine(isSelected)
    }
}
