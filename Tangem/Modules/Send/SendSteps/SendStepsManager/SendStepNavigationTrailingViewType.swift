//
//  SendStepNavigationTrailingViewType.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum SendStepNavigationTrailingViewType: Hashable {
    case qrCodeButton(action: () -> Void)

    static func == (lhs: SendStepNavigationTrailingViewType, rhs: SendStepNavigationTrailingViewType) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .qrCodeButton:
            hasher.combine("qrCodeButton")
        }
    }
}
