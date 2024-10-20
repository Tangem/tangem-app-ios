//
//  WalletConnectSolanaSignTransactionHandler.swift
//  Tangem
//
//  Created by GuitarKitty on 20.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

final class WalletConnectSolanaSignTransactionHandler {
    private let walletModel: WalletModel
    private let signer: WalletConnectSigner
    private let transaction: String

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: WalletConnectSigner,
        walletModelProvider: WalletConnectWalletModelProvider
    ) throws {
        let parameters = try request.get(WalletConnectSolanaSignTransactionDTO.Response.self)

        do {
            guard let walletModel = walletModelProvider.getModel(with: blockchainId) else {
                throw WalletConnectV2Error.walletModelNotFound(blockchainId)
            }

            self.walletModel = walletModel
            transaction = parameters.transaction
        } catch {
            let stringRepresentation = request.stringRepresentation
            AppLog.shared.debug("[WC 2.0] Failed to create sign handler. Raised error: \(error), request data: \(stringRepresentation)")
            throw WalletConnectV2Error.dataInWrongFormat(stringRepresentation)
        }

        self.signer = signer
    }

    /// Remove signature placeholder from raw transaction
    func prepareTransactionToSign() throws -> Data {
        try Data(transaction.base64Decoded()).dropFirst(Constants.signaturePlaceholderPrefixLength)
    }
}

extension WalletConnectSolanaSignTransactionHandler: WalletConnectMessageHandler {
    var event: WalletConnectEvent { .sign }

    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String {
        return "transaction: " + transaction
    }

    func handle() async throws -> RPCResult {
        let unsignedHash = try prepareTransactionToSign()
        let signedHash = try await signer.sign(data: unsignedHash, using: walletModel)

        return .response(AnyCodable(WalletConnectSolanaSignTransactionDTO.Body(signature: signedHash)))
    }
}

private enum Constants {
    static let signaturePlaceholderPrefixLength = 65
}
