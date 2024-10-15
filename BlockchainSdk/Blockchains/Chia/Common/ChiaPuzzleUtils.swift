//
//  ChiaPuzzleUtils.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 31.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/*
 - PuzzleHash Chia documentation - https://docs.chia.net/guides/crash-course/signatures/
 - Сurried and serialized signature.clsp (https://github.com/Chia-Network/chialisp-crash-course)
 */

struct ChiaPuzzleUtils {
    func getPuzzleHash(from walletPublicKey: Data) -> Data {
        return Data(hexString: Constants.puzzleReveal) + walletPublicKey + Data(hexString: Constants.fingerprint)
    }
    
    func getPuzzleHash(from address: String) throws -> Data {
        let bech32 = Bech32(variant: .bech32m)
        let dataBytes = try bech32.decode(address).checksum
        return try Data(bech32.convertBits(data: dataBytes.bytes, fromBits: 5, toBits: 8, pad: false))
    }
}

extension ChiaPuzzleUtils {
    enum Constants {
        static let puzzleReveal = "ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0"
        static let fingerprint = "ff018080"
    }
}
