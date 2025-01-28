//
//  CommonExpressExchangeDataDecoder.swift
//  Tangem
//
//  Created by Sergey Balashov on 20.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemSdk

struct CommonExpressExchangeDataDecoder: ExpressExchangeDataDecoder {
    let publicKey: String

    func decode<T: Decodable>(txDetailsJson: String, signature: String) throws -> T {
        let txDetailsData = Data(txDetailsJson.utf8)
        let signatureData = Data(hexString: signature)
        let publicKeyData = Data(hexString: publicKey).suffix(65)
        let isVerified = try CryptoUtils.verify(curve: .secp256k1, publicKey: publicKeyData, message: txDetailsData, signature: signatureData)

        guard isVerified else {
            throw ExpressExchangeDataDecoderError.invalidSignature
        }

        AppLog.info("The signature is verified")
        let details = try JSONDecoder().decode(T.self, from: txDetailsData)
        return details
    }
}

enum ExpressExchangeDataDecoderError: LocalizedError {
    case invalidSignature

    var errorDescription: String? {
        switch self {
        case .invalidSignature: "Invalid signature"
        }
    }
}
