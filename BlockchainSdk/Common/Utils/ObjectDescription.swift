//
//  ObjectDescription.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 14.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Provides output similar to the native one, useful for `CustomStringConvertible` and
/// `CustomDebugStringConvertible` conformance.
/// ```
/// // Output example:
/// <UIDimmingView: 0x14622ddc0; frame = (-414 -736; 1242 2208); opaque = NO>
/// ```
@available(*, deprecated, message: "Use TangemFoundation.objectDescription(_:userInfo:) instead.")
func objectDescription(
    _ object: AnyObject,
    userInfo: KeyValuePairs<AnyHashable, Any> = [:]
) -> String {
    let typeName = String(describing: type(of: object))
    let memoryAddress = String(describing: Unmanaged.passUnretained(object).toOpaque())
    let description = userInfo.reduce(into: [typeName + ": " + memoryAddress]) { partialResult, pair in
        partialResult.append(String(describing: pair.key) + " = " + String(describing: pair.value))
    }

    return "<" + description.joined(separator: "; ") + ">"
}
