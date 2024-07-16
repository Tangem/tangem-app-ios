//
//  AppUtils.swift
//  Tangem
//
//  Created by Andrew Son on 31/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct AppUtils {
    func canSignTransaction(for tokenItem: TokenItem) -> Bool {
        guard NFCUtils.isPoorNfcQualityDevice else {
            return true
        }

        return tokenItem.canBeSignedOnPoorNfcQualityDevice
    }

    func canStake(for tokenItem: TokenItem) -> Bool {
        guard NFCUtils.isPoorNfcQualityDevice else {
            return true
        }

        return tokenItem.canStakeOnPoorNfcQualityDevice
    }
}

private extension TokenItem {
    // We can't sign transactions at legacy devices fot these blockchains
    var canBeSignedOnPoorNfcQualityDevice: Bool {
        switch blockchain {
        case .solana:
            return isToken ? false : true
        case .chia:
            return false
        default:
            return true
        }
    }

    var canStakeOnPoorNfcQualityDevice: Bool {
        switch blockchain {
        case .solana:
            return false
        default:
            return true
        }
    }
}
