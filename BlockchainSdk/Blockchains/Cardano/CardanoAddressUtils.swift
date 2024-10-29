//
//  CardanoAddressUtils.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 31/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct CardanoAddressUtils {
    static let bech32Hrp = "addr"
    static let bech32Separator = "1"

    static var bech32Prefix: String { bech32Hrp + bech32Separator }

    static func decode(_ address: String) -> Data? {
        guard isShelleyAddress(address) else {
            return address.base58DecodedData
        }

        let bech32 = Bech32()
        guard let decoded = try? bech32.decodeLong(address) else {
            return nil
        }

        guard let converted = try? bech32.convertBits(data: Array(decoded.checksum), fromBits: 5, toBits: 8, pad: false) else {
            return nil
        }

        return Data(converted)
    }

    static func isShelleyAddress(_ address: String) -> Bool {
        address.starts(with: bech32Prefix)
    }
}
