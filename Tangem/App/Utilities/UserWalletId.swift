//
//  UserWalletId.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk

struct UserWalletId: Hashable {
    let value: Data
    let stringValue: String

    init(value: Data) {
        self.value = value
        stringValue = value.hexString
    }
}

extension UserWalletId {
    init(with walletPublicKey: Data) {
        let keyHash = walletPublicKey.getSha256()
        let key = SymmetricKey(data: keyHash)
        let authenticationCode = HMAC<SHA256>.authenticationCode(for: Constants.message, using: key)
        value = Data(authenticationCode)
        stringValue = value.hexString
    }
}

private extension UserWalletId {
    enum Constants {
        static let message = "UserWalletID".data(using: .utf8)!
    }
}
