//
//  ExampleAccountCreator.swift
//  BlockchainSdkExample
//
//  Created by Andrey Fedorov on 13.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk
import Combine

final class SimpleAccountCreator: AccountCreator {
    typealias CardProvider = () -> Card?

    private let cardProvider: CardProvider

    init(cardProvider: @escaping CardProvider) {
        self.cardProvider = cardProvider
    }

    func createAccount(blockchain: Blockchain, publicKey: Wallet.PublicKey) -> any Publisher<CreatedAccount, Error> {
        guard case .hedera = blockchain else {
            preconditionFailure("Currently, only the Hedera blockchain is supported")
        }

        guard let card = cardProvider() else {
            return Empty()
        }

        return Deferred {
            return Future { promise in
                promise(
                    Result {
                        let body = CreateAccountParam(
                            networkId: "hedera",
                            walletPublicKey: publicKey.blockchainKey.hexString
                        )

                        var request = try URLRequest(
                            url: "https://devapi.tangem-tech.com/v1/user-network-account",
                            method: .post,
                            headers: [
                                "card_id": card.cardId,
                                "card_public_key": card.cardPublicKey.hexString,
                                "Content-Type": "application/json",
                            ]
                        )

                        request.httpBody = try JSONEncoder().encode(body)

                        return request
                    }
                )
            }
        }
        .map { request in
            return URLSession
                .shared
                .dataTaskPublisher(for: request)
                .tryMap { data, response in
                    guard let response = response as? HTTPURLResponse else {
                        throw WalletError.failedToParseNetworkResponse()
                    }

                    BlockchainSDKLogger.info("Got network response with code \(response.statusCode): \(data.utf8String ?? "")")
                    return try JSONDecoder().decode(CreateAccountResult.self, from: data)
                }
                .tryMap { createAccount in
                    guard let accountId = createAccount.data?.accountId else {
                        throw createAccount.error ?? WalletError.failedToParseNetworkResponse()
                    }

                    return HederaCreatedAccount(accountId: accountId)
                }
        }
        .switchToLatest()
    }
}

// MARK: - DTO

private extension SimpleAccountCreator {
    struct CreateAccountParam: Encodable {
        let networkId: String
        let walletPublicKey: String
    }

    struct CreateAccountResult: Decodable {
        struct AccountData: Decodable {
            let accountId: String
            let walletPublicKey: String
        }

        struct Error: Decodable, LocalizedError {
            let code: Int
            let message: String?
            var errorDescription: String? { message }
        }

        let status: Bool
        let data: AccountData?
        let error: Error?
    }
}
