//
//  UserWalletIdPreflightReadFilter.swift
//  Tangem
//
//  Created by Alexander Osokin on 21.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

@available(iOS 13.0, *)
struct UserWalletIdPreflightReadFilter: PreflightReadFilter {
    private let expectedUserWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        expectedUserWalletId = userWalletId
    }

    func onCardRead(_ card: Card, environment: SessionEnvironment) throws {}

    func onFullCardRead(_ card: Card, environment: SessionEnvironment) throws {
        guard let firstPublicKey = card.wallets.first?.publicKey else {
            throw TangemSdkError.walletNotFound
        }

        let userWalletId = UserWalletId(with: firstPublicKey)
        if userWalletId != expectedUserWalletId {
            throw TangemSdkError.walletNotFound
        }
    }
}
