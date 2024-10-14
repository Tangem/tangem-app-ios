//
//  PolkadotAccountHealthInfo.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum PolkadotAccountHealthInfo {
    case nonExistentAccount
    case existingAccount(extrinsicCount: Int, nonceCount: Int)
}
