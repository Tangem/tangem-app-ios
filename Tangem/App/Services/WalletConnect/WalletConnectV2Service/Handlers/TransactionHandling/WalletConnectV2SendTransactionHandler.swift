//
//  WalletConnectV2SendTransactionHandler.swift
//  Tangem
//
//  Created by Andrew Son on 01/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import struct WalletConnectSwiftV2.AnyCodable
import enum WalletConnectSwiftV2.RPCResult

class WalletConnectV2SendTransactionHandler {
    private let wcTransaction: WalletConnectEthTransaction
    private let walletModel: WalletModel
    private let transactionBuilder: WalletConnectEthTransactionBuilder
    private let messageComposer: WalletConnectV2MessageComposable
    private let signer: TangemSigner
    private let uiDelegate: WalletConnectUIDelegate

    private var transactionToSend: Transaction?

    init(
        requestParams: AnyCodable,
        blockchainId: String,
        transactionBuilder: WalletConnectEthTransactionBuilder,
        messageComposer: WalletConnectV2MessageComposable,
        signer: TangemSigner,
        walletModelProvider: WalletConnectWalletModelProvider,
        uiDelegate: WalletConnectUIDelegate
    ) throws {
        do {
            let params = try requestParams.get([WalletConnectEthTransaction].self)

            guard let wcTransaction = params.first else {
                throw WalletConnectV2Error.missingTransaction
            }

            self.wcTransaction = wcTransaction
            walletModel = try walletModelProvider.getModel(with: wcTransaction.from, blockchainId: blockchainId)
        } catch {
            AppLog.shared.debug("[WC 2.0] Failed to create Send transaction handler. \(error)")
            throw error
        }

        self.messageComposer = messageComposer
        self.transactionBuilder = transactionBuilder
        self.signer = signer
        self.uiDelegate = uiDelegate
    }
}

extension WalletConnectV2SendTransactionHandler: WalletConnectMessageHandler {
    var event: WalletConnectEvent { .sendTx }

    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String {
        let transaction = try await transactionBuilder.buildTx(from: wcTransaction, for: walletModel)
        transactionToSend = transaction

        let message = messageComposer.makeMessage(for: transaction, walletModel: walletModel, dApp: dApp)
        return message
    }

    func handle() async throws -> RPCResult {
        guard let transaction = transactionToSend else {
            throw WalletConnectV2Error.missingTransaction
        }

        try await walletModel.send(transaction, signer: signer).async()

        Analytics.log(.transactionSent, params: [.commonSource: .transactionSourceWalletConnect])

        let selectedAction = await uiDelegate.getResponseFromUser(with: WalletConnectAsyncUIRequest<RPCResult>(
            event: .success,
            message: Localization.sendTransactionSuccess,
            approveAction: { [weak self] in
                guard
                    let lastTx = self?.walletModel.wallet.transactions.last,
                    let txHash = lastTx.hash
                else {
                    throw WalletConnectV2Error.transactionSentButNotFoundInManager
                }

                return RPCResult.response(AnyCodable(txHash))
            },
            rejectAction: { throw WalletConnectV2Error.unknown("Impossible case") }
        ))

        return try await selectedAction()
    }
}
