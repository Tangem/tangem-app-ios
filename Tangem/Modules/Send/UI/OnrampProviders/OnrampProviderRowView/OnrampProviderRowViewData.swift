//
//  OnrampProviderRowViewData.swift
//  TangemApp
//
//  Created by Sergey Balashov on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct OnrampProviderRowViewData: Identifiable {
    let id: String
    let name: String
    let iconURL: URL?
    let formattedAmount: String?
    let state: State?
    let badge: Badge
    let isSelected: Bool

    let action: () -> Void
}

extension OnrampProviderRowViewData {
    enum State: Hashable {
        case available(estimatedTime: String)
        case availableFromAmount(minAmount: String)
        case availableToAmount(maxAmount: String)
        case unavailable(reason: String)
    }

    enum Badge: Hashable {
        case bestRate
        case percent(String, signType: ChangeSignType)
    }
}

// MARK: - Hashable

extension OnrampProviderRowViewData: Hashable {
    static func == (lhs: OnrampProviderRowViewData, rhs: OnrampProviderRowViewData) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(iconURL)
        hasher.combine(formattedAmount)
        hasher.combine(badge)
        hasher.combine(isSelected)
    }
}
