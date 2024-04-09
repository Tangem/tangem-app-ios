//
//  UserWalletEncryptionKey.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

struct UserWalletEncryptionKey {
    let symmetricKey: SymmetricKey
}

extension UserWalletEncryptionKey {
    init(userWalletIdSeed: Data) {
        let keyHash = userWalletIdSeed.getSha256()
        let key = SymmetricKey(data: keyHash)
        let message = AppConstants.messageForTokensKey.data(using: .utf8)!
        let tokensSymmetricKey = HMAC<SHA256>.authenticationCode(for: message, using: key)
        let tokensSymmetricKeyData = Data(tokensSymmetricKey)

        symmetricKey = SymmetricKey(data: tokensSymmetricKeyData)
    }
}
