//
//  Fonts.swift
//  Tangem
//
//  Created by Sergey Balashov on 12.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

enum Fonts {
    enum Regular {
        static let largeTitle = Font.largeTitle
        static let title1 = Font.title.weight(.semibold)
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption1 = Font.caption
        static let caption2 = Font.caption2
    }

    enum Bold {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title1 = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.bold)
        static let title3 = Font.title3.weight(.bold)
        static let headline = Font.headline
        static let body = Font.body.weight(.semibold)
        static let callout = Font.callout.weight(.medium)
        static let subheadline = Font.subheadline.weight(.medium)
        static let footnote = Font.footnote.weight(.semibold)
        static let caption1 = Font.caption.weight(.medium)
        static let caption2 = Font.caption2.weight(.semibold)
    }

    enum RegularStatic {
        static let largeTitle = Font.system(size: 34, weight: .regular)
        static let title1 = Font.system(size: 28, weight: .semibold)
        static let title2 = Font.system(size: 22, weight: .regular)
        static let title3 = Font.system(size: 20, weight: .regular)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption1 = Font.system(size: 12, weight: .regular)
        static let caption2 = Font.system(size: 11, weight: .regular)
    }

    enum BoldStatic {
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title1 = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .bold)
        static let title3 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .semibold)
        static let callout = Font.system(size: 16, weight: .medium)
        static let subheadline = Font.system(size: 15, weight: .medium)
        static let footnote = Font.system(size: 13, weight: .semibold)
        static let caption1 = Font.system(size: 12, weight: .medium)
        static let caption2 = Font.system(size: 11, weight: .semibold)
    }
}
