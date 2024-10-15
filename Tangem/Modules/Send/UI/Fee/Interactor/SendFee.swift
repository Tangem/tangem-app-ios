//
//  SendFee.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Fee

struct SendFee: Hashable {
    let option: FeeOption
    let value: LoadingValue<Fee>
}
