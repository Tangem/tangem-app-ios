//
//  PropertyListObjectRepresentable.swift
//  Tangem
//
//  Created by Andrey Fedorov on 07.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// A mark-only protocol, represents a type that can be stored in in a property list.
/// See https://developer.apple.com/documentation/foundation/userdefaults/1414067-set for more info.
protocol PropertyListObjectRepresentable {}

extension Data: PropertyListObjectRepresentable {}

extension String: PropertyListObjectRepresentable {}

// Bridged to a `NSNumber`.
extension Bool: PropertyListObjectRepresentable {}

// Bridged to a `NSNumber`.
extension Int: PropertyListObjectRepresentable {}

// Bridged to a `NSNumber`.
extension Float: PropertyListObjectRepresentable {}

// Bridged to a `NSNumber`.
extension Double: PropertyListObjectRepresentable {}

extension Date: PropertyListObjectRepresentable {}

extension Array: PropertyListObjectRepresentable where Element: PropertyListObjectRepresentable {}

extension Dictionary: PropertyListObjectRepresentable where Key: PropertyListObjectRepresentable, Value: PropertyListObjectRepresentable {}

extension Optional: PropertyListObjectRepresentable where Wrapped: PropertyListObjectRepresentable {}
