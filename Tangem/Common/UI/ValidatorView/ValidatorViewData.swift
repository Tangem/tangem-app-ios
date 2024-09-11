//
//  ValidatorViewData.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct ValidatorViewData: Hashable, Identifiable {
    var id: Int { hashValue }

    let address: String
    let name: String
    let imageURL: URL?
    let hasMonochromeIcon: Bool
    let subtitle: AttributedString?
    let detailsType: DetailsType?

    enum DetailsType: Hashable {
        case checkmark
        case chevron(_ balance: BalanceInfo? = nil, action: (() -> Void)? = nil)
        case balance(_ balanceInfo: BalanceInfo)

        static func == (lhs: ValidatorViewData.DetailsType, rhs: ValidatorViewData.DetailsType) -> Bool {
            lhs.hashValue == rhs.hashValue
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .checkmark: hasher.combine("checkmark")
            case .chevron(let balance, _): hasher.combine(balance)
            case .balance(let balance): hasher.combine(balance)
            }
        }
    }
}
