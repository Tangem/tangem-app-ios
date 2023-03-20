//
//  UIColorConverter.swift
//  Tangem
//
//  Created by Alexander Osokin on 24.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

fileprivate struct ColorConversionError: Swift.Error {
    let reason: String
}

extension Color {
    @available(*, deprecated, message: "This is fragile and likely to break at some point. Hopefully it won't be required for long.")
    var uiColor: UIColor {
        do {
            return try convertToUIColor()
        } catch {
            assertionFailure((error as! ColorConversionError).reason)
            return uiColorFromRGB() // Fallback for iOS 14 only
        }
    }
}

fileprivate extension Color {
    var stringRepresentation: String { description.trimmingCharacters(in: .whitespacesAndNewlines) }
    var internalType: String { "\(type(of: Mirror(reflecting: self).children.first!.value))".replacingOccurrences(of: "ColorBox<(.+)>", with: "$1", options: .regularExpression) }

    func convertToUIColor() throws -> UIColor {
        if let color = try OpacityColor(color: self) {
            return try UIColor.from(swiftUIDescription: color.stringRepresentation, internalType: color.internalType).multiplyingAlphaComponent(by: color.opacityModifier)
        }
        return try UIColor.from(swiftUIDescription: stringRepresentation, internalType: internalType)
    }
}

fileprivate struct OpacityColor {
    let stringRepresentation: String
    let internalType: String
    let opacityModifier: CGFloat

    init(stringRepresentation: String, internalType: String, opacityModifier: CGFloat) {
        self.stringRepresentation = stringRepresentation
        self.internalType = internalType
        self.opacityModifier = opacityModifier
    }

    init?(color: Color) throws {
        guard color.internalType == "OpacityColor" else {
            return nil
        }
        let string = color.stringRepresentation

        let opacityRegex = try! NSRegularExpression(pattern: #"(\d+% )"#)
        let opacityLayerCount = opacityRegex.numberOfMatches(in: string, options: [], range: NSRange(string.startIndex ..< string.endIndex, in: string))
        var dumpStr = ""
        dump(color, to: &dumpStr)
        dumpStr = dumpStr.replacingOccurrences(of: #"^(?:.*\n){\#(4 * opacityLayerCount)}.*?base: "#, with: "", options: .regularExpression)

        let opacityModifier = dumpStr.split(separator: "\n")
            .suffix(1)
            .lazy
            .map { $0.replacingOccurrences(of: #"\s+-\s+opacity: "#, with: "", options: .regularExpression) }
            .map { CGFloat(Double($0)!) }
            .reduce(1, *)

        let internalTypeRegex = try! NSRegularExpression(pattern: #"^.*\n.*ColorBox<.*?([A-Za-z0-9]+)>"#)
        let matches = internalTypeRegex.matches(in: dumpStr, options: [], range: NSRange(dumpStr.startIndex ..< dumpStr.endIndex, in: dumpStr))
        guard let match = matches.first, matches.count == 1, match.numberOfRanges == 2 else {
            throw ColorConversionError(reason: "Could not parse internalType from \"\(dumpStr)\"")
            try! self.init(color: Color.black.opacity(1))
        }

        self.init(
            stringRepresentation: String(dumpStr.prefix { !$0.isNewline }),
            internalType: String(dumpStr[Range(match.range(at: 1), in: dumpStr)!]),
            opacityModifier: opacityModifier
        )
    }
}

fileprivate extension UIColor {
    static func from(swiftUIDescription description: String, internalType: String) throws -> UIColor {
        switch internalType {
        case "SystemColorType", "Resolved":
            guard let uiColor = UIColor.from(systemColorName: description) else {
                throw ColorConversionError(reason: "Could not parse SystemColorType from \"\(description)\"")
            }

            return uiColor

        case "_Resolved":
            guard description.range(of: "^#[0-9A-F]{8}$", options: .regularExpression) != nil else {
                throw ColorConversionError(reason: "Could not parse hex from \"\(description)\"")
            }

            let components = description
                .dropFirst()
                .chunks(of: 2)
                .compactMap { CGFloat.decimalFromHexPair(String($0)) }

            guard components.count == 4, let cgColor = CGColor(colorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!, components: components) else {
                throw ColorConversionError(reason: "Could not parse hex from \"\(description)\"")
            }

            return UIColor(cgColor: cgColor)

        case "UIColor":
            let sections = description.split(separator: " ")
            let colorSpace = String(sections[0])
            let components = sections[1...]
                .compactMap { Double($0) }
                .map { CGFloat($0) }

            guard components.count == 4 else {
                throw ColorConversionError(reason: "Could not parse UIColor components from \"\(description)\"")
            }
            let (r, g, b, a) = (components[0], components[1], components[2], components[3])
            return try UIColor(red: r, green: g, blue: b, alpha: a, colorSpace: colorSpace)

        case "DisplayP3":
            let regex = try! NSRegularExpression(pattern: #"^DisplayP3\(red: (-?\d+(?:\.\d+)?), green: (-?\d+(?:\.\d+)?), blue: (-?\d+(?:\.\d+)?), opacity: (-?\d+(?:\.\d+)?)"#)
            let matches = regex.matches(in: description, options: [], range: NSRange(description.startIndex ..< description.endIndex, in: description))
            guard let match = matches.first, matches.count == 1, match.numberOfRanges == 5 else {
                throw ColorConversionError(reason: "Could not parse DisplayP3 from \"\(description)\"")
            }

            let components = (0 ..< match.numberOfRanges)
                .dropFirst()
                .map { Range(match.range(at: $0), in: description)! }
                .compactMap { Double(String(description[$0])) }
                .map { CGFloat($0) }

            guard components.count == 4 else {
                throw ColorConversionError(reason: "Could not parse DisplayP3 components from \"\(description)\"")
            }

            let (r, g, b, a) = (components[0], components[1], components[2], components[3])
            return UIColor(displayP3Red: r, green: g, blue: b, alpha: a)

        case "NamedColor":
            guard description.range(of: #"^NamedColor\(name: "(.*)", bundle: .*\)$"#, options: .regularExpression) != nil else {
                throw ColorConversionError(reason: "Could not parse NamedColor from \"\(description)\"")
            }

            let nameRegex = try! NSRegularExpression(pattern: #"name: "(.*)""#)
            let name = nameRegex.matches(in: description, options: [], range: NSRange(description.startIndex ..< description.endIndex, in: description))
                .first
                .flatMap { Range($0.range(at: 1), in: description) }
                .map { String(description[$0]) }

            guard let colorName = name else {
                throw ColorConversionError(reason: "Could not parse NamedColor name from \"\(description)\"")
            }

            let bundleRegex = try! NSRegularExpression(pattern: #"bundle: .*NSBundle <(.*)>"#)
            let bundlePath = bundleRegex.matches(in: description, options: [], range: NSRange(description.startIndex ..< description.endIndex, in: description))
                .first
                .flatMap { Range($0.range(at: 1), in: description) }
                .map { String(description[$0]) }
            let bundle = bundlePath.map { Bundle(path: $0)! }

            return UIColor(named: colorName, in: bundle, compatibleWith: nil)!

        default:
            throw ColorConversionError(reason: "Unhandled type \"\(internalType)\"")
        }
    }

    static func from(systemColorName: String) -> UIColor? {
        switch systemColorName {
        case "clear": return .clear
        case "black": return .black
        case "white": return .white
        case "gray": return .systemGray
        case "red": return .systemRed
        case "green": return .systemGreen
        case "blue": return .systemBlue
        case "orange": return .systemOrange
        case "yellow": return .systemYellow
        case "pink": return .systemPink
        case "purple": return .systemPurple
        case "primary": return .label
        case "secondary": return .secondaryLabel
        default: return nil
        }
    }

    convenience init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat, colorSpace: String) throws {
        if colorSpace == "UIDisplayP3ColorSpace" {
            self.init(displayP3Red: red, green: green, blue: blue, alpha: alpha)
        } else if colorSpace == "UIExtendedSRGBColorSpace" {
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        } else if colorSpace == "kCGColorSpaceModelRGB" {
            let colorSpace = CGColorSpace(name: CGColorSpace.linearSRGB)!
            let components = [red, green, blue, alpha]
            let cgColor = CGColor(colorSpace: colorSpace, components: components)!
            self.init(cgColor: cgColor)
        } else {
            throw ColorConversionError(reason: "Unhandled colorSpace \"\(colorSpace)\"")
        }
    }

    func multiplyingAlphaComponent(by multiplier: CGFloat?) -> UIColor {
        var a: CGFloat = 0
        getWhite(nil, alpha: &a)
        return withAlphaComponent(a * (multiplier ?? 1))
    }
}

// MARK: Helper extensions

extension StringProtocol {
    func chunks(of size: Int) -> [Self.SubSequence] {
        stride(from: 0, to: count, by: size).map {
            let start = index(startIndex, offsetBy: $0)
            let end = index(start, offsetBy: size, limitedBy: endIndex) ?? endIndex
            return self[start ..< end]
        }
    }
}

extension Int {
    init?(hexString: String) {
        self.init(hexString, radix: 16)
    }
}

extension FloatingPoint {
    static func decimalFromHexPair(_ hexPair: String) -> Self? {
        guard hexPair.count == 2, let value = Int(hexString: hexPair) else {
            return nil
        }
        return Self(value) / Self(255)
    }
}
