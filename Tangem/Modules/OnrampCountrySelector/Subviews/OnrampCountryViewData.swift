//
//  OnrampCountryViewData.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 5.11.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct OnrampCountryViewData: Identifiable {
    var id: Int { hashValue }

    let image: URL?
    let name: String
    let isAvailable: Bool
    let isSelected: Bool
    let action: () -> Void
}

extension OnrampCountryViewData: Hashable {
    static func == (lhs: OnrampCountryViewData, rhs: OnrampCountryViewData) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(image)
        hasher.combine(name)
        hasher.combine(isAvailable)
        hasher.combine(isSelected)
    }
}
