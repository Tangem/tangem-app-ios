//
//  OnrampProvidersPaymentViewData.swift
//  TangemApp
//
//  Created by Sergey Balashov on 28.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct OnrampProvidersPaymentViewData: Identifiable {
    var id: Int { hashValue }

    let name: String
    let iconURL: URL
    let action: () -> Void
}

// MARK: - Hashable

extension OnrampProvidersPaymentViewData: Hashable {
    static func == (lhs: OnrampProvidersPaymentViewData, rhs: OnrampProvidersPaymentViewData) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(iconURL)
    }
}
