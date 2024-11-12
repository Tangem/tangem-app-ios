//
//  OnrampPaymentMethodRowViewData.swift
//  TangemApp
//
//  Created by Sergey Balashov on 29.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct OnrampPaymentMethodRowViewData: Identifiable {
    let id: String
    let name: String
    let iconURL: URL?
    let isSelected: Bool

    let action: () -> Void
}

// MARK: - Hashable

extension OnrampPaymentMethodRowViewData: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(iconURL)
        hasher.combine(isSelected)
    }
}
