//
//  OnrampCurrencyViewData.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 5.11.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct OnrampCurrencyViewData: Identifiable {
    var id: Int { hashValue }

    let image: URL?
    let code: String
    let name: String
    let isSelected: Bool
    let action: () -> Void
}

extension OnrampCurrencyViewData: Hashable {
    static func == (lhs: OnrampCurrencyViewData, rhs: OnrampCurrencyViewData) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(image)
        hasher.combine(code)
        hasher.combine(name)
        hasher.combine(isSelected)
    }
}
