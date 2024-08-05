//
//  ValidatorViewData.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct ValidatorViewData: Hashable, Identifiable {
    let id: String
    let name: String
    let imageURL: URL?
    let hasMonochromeIcon: Bool
    let subtitle: AttributedString?
    let detailsType: DetailsType?

    enum DetailsType: Hashable {
        case checkmark
        case chevron(_ balance: BalanceInfo? = nil)
        case balance(_ balanceInfo: BalanceInfo)
    }
}
