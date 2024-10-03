//
//  Text+NSAttributedString.swift
//  Tangem
//
//  Created by Andrew Son on 12/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension Text {
    // Taken from https://swiftui-lab.com/attributed-strings-with-swiftui/
    @available(*, deprecated, message: "Use AttributedString instead of NSAttributedString")
    init(_ attributedString: NSAttributedString) {
        self.init("")

        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { attributes, range, _ in

            var text = Text(attributedString.attributedSubstring(from: range).string)

            if let color = attributes[NSAttributedString.Key.foregroundColor] as? UIColor {
                text = text.foregroundColor(Color(color))
            }

            if let font = attributes[NSAttributedString.Key.font] as? UIFont {
                text = text.font(.init(font))
            }

            if let kern = attributes[NSAttributedString.Key.kern] as? CGFloat {
                text = text.kerning(kern)
            }

            if let striked = attributes[NSAttributedString.Key.strikethroughStyle] as? NSNumber, striked != 0 {
                if let strikeColor = (attributes[NSAttributedString.Key.strikethroughColor] as? UIColor) {
                    text = text.strikethrough(true, color: Color(strikeColor))
                } else {
                    text = text.strikethrough(true)
                }
            }

            if let baseline = attributes[NSAttributedString.Key.baselineOffset] as? NSNumber {
                text = text.baselineOffset(CGFloat(baseline.floatValue))
            }

            if let underline = attributes[NSAttributedString.Key.underlineStyle] as? NSNumber, underline != 0 {
                if let underlineColor = (attributes[NSAttributedString.Key.underlineColor] as? UIColor) {
                    text = text.underline(true, color: Color(underlineColor))
                } else {
                    text = text.underline(true)
                }
            }

            self = self + text
        }
    }
}
