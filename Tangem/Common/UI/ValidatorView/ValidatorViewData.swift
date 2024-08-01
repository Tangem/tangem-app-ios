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
    let subtitle: AttributedString?
    let detailsType: DetailsType?

    enum SubtitleType {
        case arp
        case unboundPeriod(days: String)
    }

    enum DetailsType: Hashable {
        case checkmark
        case chevron
        case balance(crypto: String, fiat: String)
    }
}
