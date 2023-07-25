//
//  WalletConnectV2Factory.swift
//  Tangem
//
//  Created by Andrew Son on 30/01/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectFactory {
    func createWCService(for model: CardViewModel) -> WalletConnectV2Service {
        let uiDelegate = WalletConnectAlertUIDelegate()
        let messageComposer = WalletConnectV2MessageComposer()
        let ethTransactionBuilder = CommonWalletConnectEthTransactionBuilder()

        let handlersFactory = WalletConnectHandlersFactory(
            signer: model.signer,
            messageComposer: messageComposer,
            uiDelegate: uiDelegate,
            ethTransactionBuilder: ethTransactionBuilder
        )
        let wcHandlersService = WalletConnectV2HandlersService(
            uiDelegate: uiDelegate,
            handlersCreator: handlersFactory
        )
        let v2Service = WalletConnectV2Service(
            with: model,
            uiDelegate: uiDelegate,
            messageComposer: messageComposer,
            wcHandlersService: wcHandlersService
        )

        handlersFactory.walletModelProvider = v2Service
        return v2Service
    }
}
