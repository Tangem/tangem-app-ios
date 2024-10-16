//
//  Color+.swift
//  Tangem
//
//  Created by Alexander Osokin on 03.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

extension UIColor {
    // DO NOT remove this
    // This is a UIColor from the new palette, used in UITextField's accessory view
    // There's no good way to convert SwiftUI dynamic Color to UIColor and retain the dark/light appearance
    // 👇👇👇 ------------------------------------ 👇👇👇
    @nonobjc static var backgroundPrimary: UIColor {
        return UIColor(named: "BackgroundPrimary")!
    }

    @nonobjc static var backgroundSecondary: UIColor {
        return UIColor(named: "BackgroundSecondary")!
    }

    @nonobjc static var backgroundPlain: UIColor {
        return UIColor(named: "BackgroundPlain")!
    }

    @nonobjc static var inputAccessoryViewTintColor: UIColor {
        return UIColor(named: "ButtonPrimary")!
    }

    @nonobjc static var textWarningColor: UIColor {
        return UIColor(named: "TextWarning")!
    }

    @nonobjc static var textAccent: UIColor {
        return UIColor(named: "TextAccent")!
    }

    @nonobjc static var textPrimary1: UIColor {
        return UIColor(named: "TextPrimary1")!
    }

    @nonobjc static var textDisabled: UIColor {
        return UIColor(named: "TextDisabled")!
    }

    @nonobjc static var iconInformative: UIColor {
        return UIColor(named: "IconInformative")!
    }

    @nonobjc static var iconAccent: UIColor {
        UIColor(named: "IconAccent")!
    }

    @nonobjc static var iconInactive: UIColor {
        UIColor(named: "IconInactive")!
    }

    @nonobjc static var iconWarning: UIColor {
        UIColor(named: "IconWarning")!
    }

    @nonobjc static var textTertiary: UIColor {
        UIColor(named: "TextTertiary")!
    }

    // ☝️☝️☝️ End of UIColors from the new palette ☝️☝️☝️

    // MARK: Background

    @nonobjc static var tangemBg: UIColor {
        return UIColor(named: "tangem_bg")!
    }

    @nonobjc static var tangemGrayDark4: UIColor {
        return UIColor(named: "tangem_gray_dark4")!
    }

    @nonobjc static var tangemGrayDark6: UIColor {
        return UIColor(named: "tangem_gray_dark6")!
    }

    @nonobjc static var tangemBlue: UIColor {
        return UIColor(named: "tangem_blue")!
    }

    @nonobjc static var tangemGrayDark: UIColor {
        return UIColor(named: "tangem_gray_dark")!
    }
}

public extension Color {
    init?(hex: String) {
        let r, g, b, a: Double

        var hexColor = hex.remove("#")
        if hexColor.count == 6 {
            hexColor += "FF"
        }

        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0

        if scanner.scanHexInt64(&hexNumber) {
            r = Double((hexNumber & 0xff000000) >> 24) / 255
            g = Double((hexNumber & 0x00ff0000) >> 16) / 255
            b = Double((hexNumber & 0x0000ff00) >> 8) / 255
            a = Double(hexNumber & 0x000000ff) / 255

            self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
            return
        }

        return nil
    }
}

extension UIColor {
    @available(iOS, deprecated: 18.0, message: "Replace with native 'Color.mix(with:by:in:)' if you are using this helper in SwiftUI only")
    func mix(with otherColor: UIColor, by fraction: CGFloat) -> UIColor {
        let clampedFraction = clamp(fraction, min: 0.0, max: 1.0)
        let invertedFraction = 1.0 - clampedFraction

        var components = (red: CGFloat(0.0), green: CGFloat(0.0), blue: CGFloat(0.0), alpha: CGFloat(0.0))
        var otherColorComponents = components // No COW for tuples`, but we don't care anyway

        getRed(
            &components.red,
            green: &components.green,
            blue: &components.blue,
            alpha: &components.alpha
        )

        otherColor.getRed(
            &otherColorComponents.red,
            green: &otherColorComponents.green,
            blue: &otherColorComponents.blue,
            alpha: &otherColorComponents.alpha
        )

        return UIColor(
            red: components.red * invertedFraction + otherColorComponents.red * clampedFraction,
            green: components.green * invertedFraction + otherColorComponents.green * clampedFraction,
            blue: components.blue * invertedFraction + otherColorComponents.blue * clampedFraction,
            alpha: components.alpha * invertedFraction + otherColorComponents.alpha * clampedFraction
        )
    }
}

extension UIColor {
    var forcedLight: UIColor {
        resolvedColor(with: .dummyLight)
    }

    var forcedDark: UIColor {
        resolvedColor(with: .dummyDark)
    }
}

// MARK: - Private implementation

private extension UITraitCollection {
    /// - Warning: Dummy, do not use as a full-fledged trait collection instance.
    static let dummyLight = UITraitCollection(userInterfaceStyle: .light)
    /// - Warning: Dummy, do not use as a full-fledged trait collection instance.
    static let dummyDark = UITraitCollection(userInterfaceStyle: .dark)
}
