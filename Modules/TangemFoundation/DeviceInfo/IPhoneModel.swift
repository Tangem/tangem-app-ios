//
//  IPhoneModel.swift
//  TangemFoundation
//
//  Created by Sergey Balashov on 21.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//
import Foundation

public enum IPhoneModel {
    case iPhone6S
    case iPhone6SPlus
    case iPhoneSE
    case iPhone7
    case iPhone7Plus
    case iPhone8
    case iPhone8Plus
    case iPhoneX
    case iPhoneXS
    case iPhoneXSMax
    case iPhoneXR
    case iPhone11
    case iPhone11Pro
    case iPhone11ProMax
    case iPhoneSE2
    case iPhone12Mini
    case iPhone12
    case iPhone12Pro
    case iPhone12ProMax
    case iPhone13Mini
    case iPhone13
    case iPhone13Pro
    case iPhone13ProMax
    case iPhoneSE3
    case iPhone14
    case iPhone14Plus
    case iPhone14Pro
    case iPhone14ProMax
    case iPhone15
    case iPhone15Plus
    case iPhone15Pro
    case iPhone15ProMax
    case iPhone16
    case iPhone16Plus
    case iPhone16Pro
    case iPhone16ProMax

    public var name: String {
        switch self {
        case .iPhone6S: return "iPhone 6S"
        case .iPhone6SPlus: return "iPhone 6S Plus"
        case .iPhoneSE: return "iPhone SE"
        case .iPhone7: return "iPhone 7"
        case .iPhone7Plus: return "iPhone 7 Plus"
        case .iPhone8: return "iPhone 8"
        case .iPhone8Plus: return "iPhone 8 Plus"
        case .iPhoneX: return "iPhone X"
        case .iPhoneXS: return "iPhone XS"
        case .iPhoneXSMax: return "iPhone XS Max"
        case .iPhoneXR: return "iPhone XR"
        case .iPhone11: return "iPhone 11"
        case .iPhone11Pro: return "iPhone 11 Pro"
        case .iPhone11ProMax: return "iPhone 11 Pro Max"
        case .iPhoneSE2: return "iPhone SE 2"
        case .iPhone12Mini: return "iPhone 12 Mini"
        case .iPhone12: return "iPhone 12"
        case .iPhone12Pro: return "iPhone 12 Pro"
        case .iPhone12ProMax: return "iPhone 12 Pro Max"
        case .iPhone13Mini: return "iPhone 13 Mini"
        case .iPhone13: return "iPhone 13"
        case .iPhone13Pro: return "iPhone 13 Pro"
        case .iPhone13ProMax: return "iPhone 13 Pro Max"
        case .iPhoneSE3: return "iPhone SE 3"
        case .iPhone14: return "iPhone 14"
        case .iPhone14Plus: return "iPhone 14 Plus"
        case .iPhone14Pro: return "iPhone 14 Pro"
        case .iPhone14ProMax: return "iPhone 14 Pro Max"
        case .iPhone15: return "iPhone 15"
        case .iPhone15Plus: return "iPhone 15 Plus"
        case .iPhone15Pro: return "iPhone 15 Pro"
        case .iPhone15ProMax: return "iPhone 15 Pro Max"
        case .iPhone16: return "iPhone 16"
        case .iPhone16Plus: return "iPhone 16 Plus"
        case .iPhone16Pro: return "iPhone 16 Pro"
        case .iPhone16ProMax: return "iPhone 16 Pro Max"
        }
    }

    public init?() {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelIdentifier = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String(validatingUTF8: ptr)
            }
        }

        guard let modelIdentifier = modelIdentifier else {
            return nil
        }

        switch modelIdentifier {
        case "iPhone8,1": self = .iPhone6S
        case "iPhone8,2": self = .iPhone6SPlus
        case "iPhone8,4": self = .iPhoneSE
        case "iPhone9,1", "iPhone9,3": self = .iPhone7
        case "iPhone9,2", "iPhone9,4": self = .iPhone7Plus
        case "iPhone10,1", "iPhone10,4": self = .iPhone8
        case "iPhone10,2", "iPhone10,5": self = .iPhone8Plus
        case "iPhone10,3", "iPhone10,6": self = .iPhoneX
        case "iPhone11,2": self = .iPhoneXS
        case "iPhone11,4", "iPhone11,6": self = .iPhoneXSMax
        case "iPhone11,8": self = .iPhoneXR
        case "iPhone12,1": self = .iPhone11
        case "iPhone12,3": self = .iPhone11Pro
        case "iPhone12,5": self = .iPhone11ProMax
        case "iPhone12,8": self = .iPhoneSE2
        case "iPhone13,1": self = .iPhone12Mini
        case "iPhone13,2": self = .iPhone12
        case "iPhone13,3": self = .iPhone12Pro
        case "iPhone13,4": self = .iPhone12ProMax
        case "iPhone14,4": self = .iPhone13Mini
        case "iPhone14,5": self = .iPhone13
        case "iPhone14,2": self = .iPhone13Pro
        case "iPhone14,3": self = .iPhone13ProMax
        case "iPhone14,6": self = .iPhoneSE3
        case "iPhone14,7": self = .iPhone14
        case "iPhone14,8": self = .iPhone14Plus
        case "iPhone15,2": self = .iPhone14Pro
        case "iPhone15,3": self = .iPhone14ProMax
        case "iPhone15,4": self = .iPhone15
        case "iPhone15,5": self = .iPhone15Plus
        case "iPhone16,1": self = .iPhone15Pro
        case "iPhone16,2": self = .iPhone15ProMax
        case "iPhone17,1": self = .iPhone16Pro
        case "iPhone17,2": self = .iPhone16ProMax
        case "iPhone17,3": self = .iPhone16
        case "iPhone17,4": self = .iPhone16Plus
        default:
            return nil
        }
    }
}
