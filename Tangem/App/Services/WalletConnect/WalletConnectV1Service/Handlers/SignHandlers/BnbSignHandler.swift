//
//  BnbSignHandler.swift
//  Tangem
//
//  Created by Andrew Son on 29/06/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import Combine
import BlockchainSdk
import TangemSdk

private protocol BinanceMessage: Codable {}

private struct TransactionMessage: BinanceMessage {
    struct Coin: Codable {
        let amount: Int64
        let denom: String
    }

    struct Item: Codable {
        let address: String
        let coins: [Coin]
    }

    let inputs: [Item]
    let outputs: [Item]
}

private struct TradeMessage: BinanceMessage {
    let id: String
    let ordertype: Int
    let price: Int
    let quantity: Int64
    let sender: String
    let side: Int
    let symbol: String
    let timeinforce: Int
}

private struct BinanceSingMessage<T: BinanceMessage>: Codable {
    let accountNumber: String
    let chainId: String
    let data: String?
    let memo: String
    let messages: [T]
    let sequence: String
    let source: String

    private enum CodingKeys: String, CodingKey {
        case accountNumber = "account_number"
        case chainId = "chain_id"
        case messages = "msgs"
        case data
        case memo
        case sequence
        case source
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accountNumber, forKey: .accountNumber)
        try container.encode(chainId, forKey: .chainId)
        try container.encode(data, forKey: .data)
        try container.encode(memo, forKey: .memo)
        try container.encode(messages, forKey: .messages)
        try container.encode(sequence, forKey: .sequence)
        try container.encode(source, forKey: .source)
    }
}

private struct BnbMessageDTO {
    let address: String
    let data: Data
    let message: String
}

class BnbSignHandler: WalletConnectSignHandler {
    override var action: WalletConnectAction { .bnbSign }

    override func handle(request: Request) {
        guard
            let bnbMessage = extractMessage(from: request),
            let session = dataSource?.session(for: request)
        else {
            delegate?.sendInvalid(request)
            return
        }

        let message = Localization.walletConnectBnbSignMessage(session.session.dAppInfo.peerMeta.name, bnbMessage.message)
        askToSign(in: session, request: request, message: message, dataToSign: bnbMessage.data)
    }

    override func signatureResponse(for signature: String, session: WalletConnectSession, request: Request) -> Response {
        struct BnbSignResponse: Encodable {
            let signature: String
            let publicKey: String
        }

        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .sortedKeys
            let rawKey = session.wallet.derivedPublicKey ?? session.wallet.walletPublicKey
            let pubkey = try! Secp256k1Key(with: rawKey).decompress().hexString
            let signResponse = BnbSignResponse(signature: signature, publicKey: pubkey)

            // Important note!
            // When encoding data to json string you must escape all " in string. Otherwise Binance will return Order error - JSON.parse: unexpected character at line 1 column 2
            // Json in "result" field must be: {\"publicKey\":\"...\",\"signature\":\"...\"}"}
            // ex.
            // {"id":1,"jsonrpc":"2.0","result":"{\"publicKey\":\"042446499C8D252964AB7AE7FD10785641BFAD8222780430CEF003DEC0E5B632CBA57CC468C1A76AF540B4A3A5D050DBA2AEE43052D6A9D6BF00B6D3A6CA9F2D5E\",\"signature\":\"5152CB5BB8C7594DD07231C6934D4CFB6A113124B6B21A98CBB60636C8F3CA9C4662EB70D3F75FFB5B3C5AD17BA0FF5D8C8E54A2BFFD4D780213B15246DB04E2\"}"}
            let encodedString = String(data: try jsonEncoder.encode(signResponse), encoding: .utf8)!
            AppLog.shared.debug("Encoded string result for BNB sing: \(encodedString)")
            return try .init(url: request.url, value: encodedString, id: request.id!)
        } catch {
            AppLog.shared.error(error)
            return .reject(request)
        }
    }

    override func sign(data: Data, walletPublicKey: Wallet.PublicKey, signer: TangemSigner) -> AnyPublisher<String, Error> {
        let hash = data.sha256()

        return signer.sign(hash: hash, walletPublicKey: walletPublicKey)
            .tryMap { $0.hexString }
            .eraseToAnyPublisher()
    }

    private func extractMessage(from request: Request) -> BnbMessageDTO? {
        let jsonEncoder = JSONEncoder()
        // Data for sign must not contain escaping slashes. Otherwise Dapp most likely will return signature verification failed
        jsonEncoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let blockchain = Blockchain.binance(testnet: false)
        let decimalValue = blockchain.decimalValue

        // This part is not tested. Can't find service that will give ability to send transaction between wallets via WalletConnect interface
        if let transactionMessage = try? request.parameter(of: BinanceSingMessage<TransactionMessage>.self, at: 0) {
            guard
                let input = transactionMessage.messages.first?.inputs.first,
                let output = transactionMessage.messages.first?.outputs.first
            else { return nil }

            let address = input.address
            let currency = input.coins.first?.denom ?? blockchain.currencySymbol
            let amountToSend: Int64 = input.coins.reduce(0) { $0 + ($1.denom == currency ? $1.amount : 0) }
            let uiMessage = Localization.walletConnectBnbTransactionMessage(
                address,
                output.address,
                (Decimal(amountToSend) / decimalValue).description
            )

            let encodedData = try! jsonEncoder.encode(transactionMessage)
            AppLog.shared.debug("Encoded BNB transaction message: \(String(data: encodedData, encoding: .utf8)!)")
            return .init(address: address, data: encodedData, message: uiMessage)

            // Trading can be tested here: https://testnet.binance.org/en/
        } else if let tradeMessage = try? request.parameter(of: BinanceSingMessage<TradeMessage>.self, at: 0) {
            guard let address = tradeMessage.messages.first?.sender else { return nil }

            var uiMessage = ""
            let numberOfMessages = tradeMessage.messages.count
            for i in 0 ..< numberOfMessages {
                let message = tradeMessage.messages[i]
                let price = Decimal(message.price) / decimalValue
                let quantity = Decimal(message.quantity) / decimalValue
                uiMessage.append(Localization.walletConnectBnbTradeOrderMessage(
                    message.symbol,
                    "\(price.description) \(blockchain.currencySymbol)",
                    "\(quantity)",
                    "\(price * quantity) \(blockchain.currencySymbol)"
                )
                )
                if i < (numberOfMessages - 1) {
                    uiMessage += "\n\n"
                }
            }

            let encodedData = try! jsonEncoder.encode(tradeMessage)
            AppLog.shared.debug("Encoded BNB trade order: \(String(data: encodedData, encoding: .utf8)!)")
            return .init(address: address, data: encodedData, message: uiMessage)
        }

        return nil
    }
}

class BnbSuccessHandler: TangemWalletConnectRequestHandler {
    struct ConfirmationResponse: Decodable {
        let ok: Bool
        let error: String?
    }

    weak var delegate: WalletConnectHandlerDelegate?
    weak var dataSource: WalletConnectHandlerDataSource?

    var action: WalletConnectAction { .bnbTxConfirmation }

    init(delegate: WalletConnectHandlerDelegate, dataSource: WalletConnectHandlerDataSource) {
        self.delegate = delegate
        self.dataSource = dataSource
    }

    func handle(request: Request) {
        do {
            let response = try request.parameter(of: ConfirmationResponse.self, at: 0)

            if response.ok {
                try delegate?.send(Response(url: request.url, value: "", id: request.id!), for: action)
                return
            }

            guard let error = response.error, !error.isEmpty else {
                return
            }

            delegate?.sendReject(for: request, with: error, for: action)
        } catch {
            AppLog.shared.error(error)
            delegate?.sendInvalid(request)
        }
    }
}
