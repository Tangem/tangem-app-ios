//
//  MainHeaderSubtitleInfo.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct MainHeaderSubtitleInfo {
    let messages: [String]
    let formattingOption: MainHeaderSubtitleFormattingOption

    static let empty: MainHeaderSubtitleInfo = .init(messages: [], formattingOption: .default)
}

extension MainHeaderSubtitleInfo {
    enum MainHeaderSubtitleFormattingOption {
        case `default`
        case error

        var textColor: Color {
            switch self {
            case .default: return Colors.Text.tertiary
            case .error: return Colors.Text.attention
            }
        }

        var font: Font {
            Fonts.Regular.caption2
        }
    }
}
