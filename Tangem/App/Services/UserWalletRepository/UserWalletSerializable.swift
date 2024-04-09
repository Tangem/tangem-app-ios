//
//  UserWalletSerializable.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol UserWalletSerializable {
    func serialize() -> StoredUserWallet
}
