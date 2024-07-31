//
//  UIFonts.swift
//  Tangem
//
//  Created by Andrew Son on 17/03/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit

enum UIFonts {
    enum Regular {
        static var body: UIFont {
            FeatureProvider.isAvailable(.dynamicFonts) ? .preferredFont(forTextStyle: .body) : .systemFont(ofSize: 17, weight: .regular)
        }

        static var subheadline: UIFont {
            FeatureProvider.isAvailable(.dynamicFonts) ? .preferredFont(forTextStyle: .subheadline) : .systemFont(ofSize: 15, weight: .regular)
        }

        static var footnote: UIFont {
            FeatureProvider.isAvailable(.dynamicFonts) ? .preferredFont(forTextStyle: .footnote) : .systemFont(ofSize: 13, weight: .regular)
        }

        static var caption2: UIFont {
            FeatureProvider.isAvailable(.dynamicFonts) ? .preferredFont(forTextStyle: .caption2) : .systemFont(ofSize: 11, weight: .regular)
        }
    }

    enum Bold {
        static var footnote: UIFont {
            FeatureProvider.isAvailable(.dynamicFonts) ? .preferredFont(forTextStyle: .footnote) : .systemFont(ofSize: 13, weight: .semibold)
        }
    }
}
