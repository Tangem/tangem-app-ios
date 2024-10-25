//
//  RewardViewData.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct RewardViewData: Hashable, Identifiable {
    var id: Int { hashValue }

    let state: State
}

extension RewardViewData {
    enum State: Hashable {
        case noRewards
        case automaticRewards
        case rewards(claimable: Bool, fiatFormatted: String, cryptoFormatted: String, action: () -> Void)

        static func == (lhs: RewardViewData.State, rhs: RewardViewData.State) -> Bool {
            lhs.hashValue == rhs.hashValue
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .noRewards:
                hasher.combine("noRewards")
            case .automaticRewards:
                hasher.combine("automaticRewards")
            case .rewards(let claimable, let fiatFormatted, let cryptoFormatted, _):
                hasher.combine(claimable)
                hasher.combine(fiatFormatted)
                hasher.combine(cryptoFormatted)
            }
        }
    }
}
