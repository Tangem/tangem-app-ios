//
//  WalletConnectV2PersonalSignHandler.swift
//  Tangem
//
//  Created by Andrew Son on 30/01/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import enum BlockchainSdk.Blockchain
import struct WalletConnectSwiftV2.AnyCodable
import enum WalletConnectSwiftV2.RPCResult

struct WalletConnectV2PersonalSignHandler {
    private let message: String
    private let signer: WalletConnectSigner
    private let walletModel: WalletModel

    private var dataToSign: Data {
        let hexData = Data(hex: message)
        // If received message is not a hex string, then convert it to bytes
        if hexData.isEmpty, !message.starts(with: "0x") {
            return message.data(using: .utf8) ?? Data()
        } else {
            return hexData
        }
    }

    init(
        request: AnyCodable,
        blockchain: Blockchain,
        signer: WalletConnectSigner,
        walletModelProvider: WalletConnectV2WalletModelProvider
    ) throws {
        let castedParams: [String]
        do {
            castedParams = try request.get([String].self)
            if castedParams.count < 2 {
                throw WalletConnectV2Error.notEnoughDataInRequest(String(describing: request))
            }

            let targetAddress = castedParams[1]
            walletModel = try walletModelProvider.getModel(with: targetAddress, in: blockchain)
        } catch {
            let stringRepresentation = request.stringRepresentation
            AppLog.shared.debug("[WC 2.0] Failed to create sign handler. Raised error: \(error), request data: \(stringRepresentation)")
            throw WalletConnectV2Error.dataInWrongFormat(stringRepresentation)
        }

        message = castedParams[0]
        self.signer = signer
    }

    private func makePersonalMessageData(_ data: Data) -> Data {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let prefixData = (prefix + "\(data.count)").data(using: .utf8)!
        return prefixData + data
    }
}

extension WalletConnectV2PersonalSignHandler: WalletConnectMessageHandler {
    var event: WalletConnectEvent { .sign }

    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String {
        let message = Localization.walletConnectPersonalSignMessage(dApp.name, dataToSign.hexString)
        return Localization.walletConnectAlertSignMessage(message)
    }

    func handle() async throws -> RPCResult {
        let personalMessageData = makePersonalMessageData(dataToSign)
        let hash = personalMessageData.sha3(.keccak256)
        do {
            let signedMessage = try await signer.sign(data: hash, using: walletModel)
            return .response(AnyCodable(signedMessage))
        } catch {
            AppLog.shared.debug("[WC 2.0] Failed to sign message. \(error)")
            return .error(.internalError)
        }
    }
}
