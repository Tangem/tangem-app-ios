//
//  SendMainButtonType.swift
//  Tangem
//
//  Created by Andrey Chukavin on 29.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum SendMainButtonType {
    case next
    case `continue`
    case send
    case close
}

extension SendMainButtonType {
    var title: String {
        switch self {
        case .next:
            Localization.commonNext
        case .continue:
            Localization.commonContinue
        case .send:
            Localization.commonSend
        case .close:
            Localization.commonClose
        }
    }

    var icon: MainButton.Icon? {
        switch self {
        case .send:
            .trailing(Assets.tangemIcon)
        default:
            nil
        }
    }
}
