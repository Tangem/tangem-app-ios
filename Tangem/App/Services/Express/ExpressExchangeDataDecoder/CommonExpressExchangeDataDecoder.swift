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

    func decode(txDetailsJson: String, signature: String) throws -> DecodedTransactionDetails {
        let txDetailsData = Data(txDetailsJson.utf8)
        let signatureData = Data(hexString: signature)
        let publicKeyData = Data(hexString: publicKey).suffix(65)
        let isVerified = try CryptoUtils.verify(curve: .secp256k1, publicKey: publicKeyData, message: txDetailsData, signature: signatureData)

        guard isVerified else {
            throw ExpressExchangeDataDecoderError.invalidSignature
        }

        AppLog.shared.debug("[Express] The signature is verified")
        let details = try JSONDecoder().decode(DecodedTransactionDetails.self, from: txDetailsData)
        return details
    }
}

enum ExpressExchangeDataDecoderError: Error {
    case invalidSignature
}
