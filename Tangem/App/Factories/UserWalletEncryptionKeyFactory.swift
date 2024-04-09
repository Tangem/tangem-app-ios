//
//  UserWalletEncryptionKeyFactory.swift
//  Tangem
//
//  Created by Andrey Chukavin on 21.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class UserWalletEncryptionKeyFactory {
    func encryptionKey(for userWallet: StoredUserWallet) -> UserWalletEncryptionKey? {
        let cardInfo = userWallet.cardInfo()
        let config = UserWalletConfigFactory(cardInfo).makeConfig()

        guard let userWalletIdSeed = config.userWalletIdSeed else { return nil }

        return UserWalletEncryptionKey(userWalletIdSeed: userWalletIdSeed)
    }
}
