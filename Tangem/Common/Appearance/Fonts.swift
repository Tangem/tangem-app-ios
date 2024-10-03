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
        static let largeTitle: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.largeTitle : StaticFonts.largeTitle

        static let title1: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.title1 : StaticFonts.title1

        static let title2: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.title2 : StaticFonts.title2

        static let title3: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.title3 : StaticFonts.title3

        static let headline: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.headline : StaticFonts.headline

        static let body: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.body : StaticFonts.body

        static let callout: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.callout : StaticFonts.callout

        static let subheadline: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.subheadline : StaticFonts.subheadline

        static let footnote: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.footnote : StaticFonts.footnote

        static let caption1: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.caption1 : StaticFonts.caption1

        static let caption2: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.caption2 : StaticFonts.caption2
    }

    enum Bold {
        static let largeTitle: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.largeTitleBold : StaticFonts.largeTitleBold

        static let title1: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.title1Bold : StaticFonts.title1Bold

        static let title2: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.title2Bold : StaticFonts.title2Bold

        static let title3: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.title3Bold : StaticFonts.title3Bold

        static let headline = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.headline : StaticFonts.headline

        static let body: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.bodySemibold : StaticFonts.bodySemibold

        static let callout: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.calloutMedium : StaticFonts.calloutMedium

        static let subheadline: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.subheadlineMedium : StaticFonts.subheadlineMedium

        static let footnote: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.footnoteSemibold : StaticFonts.footnoteSemibold

        static let caption1: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.caption1Medium : StaticFonts.caption1Medium

        static let caption2: Font = FeatureProvider.isAvailable(.dynamicFonts) ? DynamicFonts.caption2Semibold : StaticFonts.caption2Semibold
    }
}

private enum StaticFonts {
    static let largeTitle: Font = .system(size: 34, weight: .regular)
    static let title1: Font = .system(size: 28, weight: .semibold)
    static let title2: Font = .system(size: 22, weight: .regular)
    static let title3: Font = .system(size: 20, weight: .regular)
    static let headline: Font = .system(size: 17, weight: .semibold)
    static let body: Font = .system(size: 17, weight: .regular)
    static let callout: Font = .system(size: 16, weight: .regular)
    static let subheadline: Font = .system(size: 15, weight: .regular)
    static let footnote: Font = .system(size: 13, weight: .regular)
    static let caption1: Font = .system(size: 12, weight: .regular)
    static let caption2: Font = .system(size: 11, weight: .regular)

    static let largeTitleBold: Font = .system(size: 34, weight: .bold)
    static let title1Bold: Font = .system(size: 28, weight: .bold)
    static let title2Bold: Font = .system(size: 22, weight: .bold)
    static let title3Bold: Font = .system(size: 20, weight: .semibold)
    static let headlineSemibold: Font = .system(size: 17, weight: .semibold)
    static let bodySemibold: Font = .system(size: 17, weight: .semibold)
    static let calloutMedium: Font = .system(size: 16, weight: .medium)
    static let subheadlineMedium: Font = .system(size: 15, weight: .medium)
    static let footnoteSemibold: Font = .system(size: 13, weight: .semibold)
    static let caption1Medium: Font = .system(size: 12, weight: .medium)
    static let caption2Semibold: Font = .system(size: 11, weight: .semibold)
}

private enum DynamicFonts {
    static let largeTitle: Font = .largeTitle
    static let title1: Font = .title.weight(.semibold)
    static let title2: Font = .title2
    static let title3: Font = .title3
    static let headline: Font = .headline
    static let body: Font = .body
    static let callout: Font = .callout
    static let subheadline: Font = .subheadline
    static let footnote: Font = .footnote
    static let caption1: Font = .caption
    static let caption2: Font = .caption2

    static let largeTitleBold: Font = .largeTitle.weight(.bold)
    static let title1Bold: Font = .title.weight(.bold)
    static let title2Bold: Font = .title2.weight(.bold)
    static let title3Bold: Font = .title3.weight(.bold)
    static let bodySemibold: Font = .body.weight(.semibold)
    static let calloutMedium: Font = .callout.weight(.medium)
    static let subheadlineMedium: Font = .subheadline.weight(.medium)
    static let footnoteSemibold: Font = .footnote.weight(.semibold)
    static let caption1Medium: Font = .caption.weight(.medium)
    static let caption2Semibold: Font = .caption2.weight(.semibold)
}
