//
//  SendTransactionDispatcherFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendTransactionDispatcherFactory {
    let walletModel: WalletModel
    let signer: TangemSigner

    func makeSendDispatcher() -> SendTransactionDispatcher {
        if walletModel.isDemo {
            return DemoSendTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
        }

        return CommonSendTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
    }
}
