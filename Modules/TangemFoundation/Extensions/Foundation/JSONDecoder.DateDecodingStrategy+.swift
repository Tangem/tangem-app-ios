//
//  JSONDecoder.DateDecodingStrategy+.swift
//  TangemFoundation
//
//  Created by m3g0byt3 on 11.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public extension JSONDecoder.DateDecodingStrategy {
    /// - Note: Standard `JSONDecoder.DateDecodingStrategy.iso8601` uses `.withInternetDateTime` format of the
    /// `ISO8601DateFormatter` and won't parse milliseconds, see https://stackoverflow.com/a/46538423 for details.
    static var iso8601WithFractionalSeconds: JSONDecoder.DateDecodingStrategy = {
        let dateFormatter = DateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        return .formatted(dateFormatter)
    }()
}
