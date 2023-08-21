//
//  Color+.swift
//  Tangem
//
//  Created by Alexander Osokin on 03.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

extension Color {
    // MARK: Primary

    @nonobjc static var tangemGreen: Color {
        return Color("tangem_green")
    }

    @nonobjc static var tangemGreen2: Color {
        return Color("tangem_green2")
    }

    // MARK: Complimentary

    @nonobjc static var tangemWarning: Color {
        return Color("tangem_warning")
    }

    @nonobjc static var tangemBlue: Color {
        return Color("tangem_blue")
    }

    @nonobjc static var tangemBlue1: Color {
        return Color("tangem_blue1")
    }

    @nonobjc static var tangemBlue2: Color {
        return Color("tangem_blue2")
    }

    @nonobjc static var tangemBlue3: Color {
        return Color("tangem_blue3")
    }

    @nonobjc static var tangemCritical: Color {
        return Color(.tangemCritical)
    }

    // MARK: Gray Dark

    @nonobjc static var tangemGrayDark1: Color {
        return Color("tangem_gray_dark_1")
    }

    @nonobjc static var tangemGrayDark: Color {
        return Color("tangem_gray_dark")
    }

    @nonobjc static var tangemGrayDark2: Color {
        return Color("tangem_gray_dark2")
    }

    @nonobjc static var tangemGrayDark3: Color {
        return Color("tangem_gray_dark3")
    }

    @nonobjc static var tangemGrayDark4: Color {
        return Color("tangem_gray_dark4")
    }

    @nonobjc static var tangemGrayDark5: Color {
        return Color("tangem_gray_dark5")
    }

    @nonobjc static var tangemGrayDark6: Color {
        return Color("tangem_gray_dark6")
    }

    // MARK: Gray Light

    @nonobjc static var tangemGrayLight4: Color {
        return Color("tangem_gray_light4")
    }

    @nonobjc static var tangemGrayLight5: Color {
        return Color("tangem_gray_light5")
    }

    @nonobjc static var tangemGrayLight6: Color {
        return Color("tangem_gray_light6")
    }

    @nonobjc static var tangemTextGray: Color {
        return Color("tangem_text_gray")
    }

    @nonobjc static var tangemGrayLight7: Color {
        return Color("tangem_gray_light7")
    }

    @nonobjc static var tangemSkeletonGray: Color {
        return Color("tangem_skeleton_gray")
    }

    @nonobjc static var tangemSkeletonGray2: Color {
        return Color("tangem_skeleton_gray2")
    }

    @nonobjc static var tangemHoverButton: Color {
        return Color("tangem_btn_hover_bg")
    }

    // MARK: Background

    @nonobjc static var tangemBgGray: Color {
        return Color(.tangemBgGray)
    }

    @nonobjc static var tangemBgGray2: Color {
        return Color(.tangemBgGray2)
    }

    @nonobjc static var tangemBgGray3: Color {
        return Color(.tangemBgGray3)
    }

    @nonobjc static var tangemBg: Color {
        return Color("tangem_bg")
    }

    // MARK: Tints

    @nonobjc static var tangemBlueLight: Color {
        return Color("tangem_blue_light")
    }

    // MARK: Misc

    @nonobjc static var underlyingCardBackground1: Color {
        return Color("underlying-card-background1")
    }

    @nonobjc static var underlyingCardBackground2: Color {
        return Color("underlying-card-background2")
    }
}

extension UIColor {
    // MARK: Background

    @nonobjc static var tangemBgGray: UIColor {
        return UIColor(named: "tangem_bg_gray")!
    }

    @nonobjc static var tangemBgGray2: UIColor {
        return UIColor(named: "tangem_bg_gray2")!
    }

    @nonobjc static var tangemBgGray3: UIColor {
        return UIColor(named: "tangem_bg_gray3")!
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

    @nonobjc static var tangemCritical: UIColor {
        UIColor(named: "tangem_critical")!
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
