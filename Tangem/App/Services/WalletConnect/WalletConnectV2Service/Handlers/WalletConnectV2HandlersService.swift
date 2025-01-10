//
//  WalletConnectV2HandlersService.swift
//  Tangem
//
//  Created by Andrew Son on 30/01/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import enum BlockchainSdk.Blockchain
import struct WalletConnectSign.Request
import enum JSONRPC.RPCResult

protocol WalletConnectV2HandlersServicing {
    func handle(
        _ request: Request,
        from dApp: WalletConnectSavedSession.DAppInfo,
        blockchainId: String,
        signer: TangemSigner,
        walletModelProvider: WalletConnectWalletModelProvider
    ) async throws -> RPCResult
}

struct WalletConnectV2HandlersService {
    private let uiDelegate: WalletConnectAlertUIDelegate
    private let handlersCreator: WalletConnectHandlersCreator

    private static let userRejectedResult = RPCResult.error(.init(code: 0, message: "User rejected sign"))

    init(
        uiDelegate: WalletConnectAlertUIDelegate,
        handlersCreator: WalletConnectHandlersCreator
    ) {
        self.uiDelegate = uiDelegate
        self.handlersCreator = handlersCreator
    }

    private func getHandler(for request: Request, blockchainId: String, signer: TangemSigner, walletModelProvider: WalletConnectWalletModelProvider) throws -> WalletConnectMessageHandler {
        let method = request.method
        guard let wcAction = WalletConnectAction(rawValue: method) else {
            throw WalletConnectV2Error.unsupportedWCMethod(method)
        }

        return try handlersCreator.createHandler(for: wcAction, with: request.params, blockchainId: blockchainId, signer: signer, walletModelProvider: walletModelProvider)
    }
}

extension WalletConnectV2HandlersService: WalletConnectV2HandlersServicing {
    func handle(
        _ request: Request,
        from dApp: WalletConnectSavedSession.DAppInfo,
        blockchainId: String,
        signer: TangemSigner,
        walletModelProvider: WalletConnectWalletModelProvider
    ) async throws -> RPCResult {
        let handler = try getHandler(for: request, blockchainId: blockchainId, signer: signer, walletModelProvider: walletModelProvider)

        let selectedAction = await uiDelegate.getResponseFromUser(with: WalletConnectAsyncUIRequest(
            event: handler.event,
            message: try await handler.messageForUser(from: dApp),
            approveAction: {
                return try await handler.handle()
            },
            rejectAction: {
                return Self.userRejectedResult
            }
        ))

        return try await selectedAction()
    }
}
