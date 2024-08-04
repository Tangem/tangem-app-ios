//
//  SendTxError+.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension Error {
    var signingWasCancelled: Bool {
        (self as? SendTxError)?.error.toTangemSdkError().isUserCancelled == true
    }
}
