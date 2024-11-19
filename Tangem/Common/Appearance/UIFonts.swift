//
//  UIFonts.swift
//  Tangem
//
//  Created by Andrew Son on 17/03/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit

enum UIFonts {
    struct RegularFont {
        let isDynamic: () -> Bool

        var body: UIFont {
            isDynamic() ? .preferredFont(forTextStyle: .body) : .systemFont(ofSize: 17, weight: .regular)
        }

        var subheadline: UIFont {
            isDynamic() ? .preferredFont(forTextStyle: .subheadline) : .systemFont(ofSize: 15, weight: .regular)
        }

        var footnote: UIFont {
            isDynamic() ? .preferredFont(forTextStyle: .footnote) : .systemFont(ofSize: 13, weight: .regular)
        }

        var caption2: UIFont {
            isDynamic() ? .preferredFont(forTextStyle: .caption2) : .systemFont(ofSize: 11, weight: .regular)
        }
    }

    struct BoldFont {
        let isDynamic: () -> Bool

        var callout: UIFont {
            let staticFont = UIFont.systemFont(ofSize: 16, weight: .medium)

            if isDynamic() {
                let metrics = UIFontMetrics(forTextStyle: .callout)
                return metrics.scaledFont(for: staticFont)
            }

            return staticFont
        }
    }

    static let Regular = RegularFont(isDynamic: { FeatureProvider.isAvailable(.dynamicFonts) })

    static let Bold = BoldFont(isDynamic: { FeatureProvider.isAvailable(.dynamicFonts) })

    static let RegularStatic = RegularFont(isDynamic: { false })
}
