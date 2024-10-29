//
//  WalletConnectSigner.swift
//  Tangem
//
//  Created by GuitarKitty on 15.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol WalletConnectSigner {
    func sign(data: Data, using walletModel: WalletModel) async throws -> String
}
