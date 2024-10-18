//
//  FilecoinNetworkService.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

class FilecoinNetworkService: MultiNetworkProvider {
    let providers: [FilecoinNetworkProvider]
    var currentProviderIndex = 0

    init(providers: [FilecoinNetworkProvider]) {
        self.providers = providers
    }

    func getAccountInfo(
        address: String
    ) -> AnyPublisher<FilecoinAccountInfo, Error> {
        providerPublisher { provider in
            provider
                .getActorInfo(address: address)
                .tryMap { response in
                    guard let balance = Decimal(stringValue: response.balance) else {
                        throw WalletError.failedToParseNetworkResponse()
                    }

                    return FilecoinAccountInfo(
                        balance: balance,
                        nonce: response.nonce
                    )
                }
                .tryCatch { error -> AnyPublisher<FilecoinAccountInfo, Error> in
                    if let error = error as? JSONRPC.APIError, error.code == 1 {
                        return .anyFail(
                            error: WalletError.noAccount(
                                message: Localization.noAccountSendToCreate,
                                amountToCreate: 0
                            )
                        )
                    }
                    return .anyFail(error: error)
                }
                .eraseToAnyPublisher()
        }
    }

    func getEstimateMessageGas(
        message: FilecoinMessage
    ) -> AnyPublisher<FilecoinResponse.GetEstimateMessageGas, Error> {
        providerPublisher { provider in
            provider.getEstimateMessageGas(message: message)
        }
    }

    func submitTransaction(
        signedMessage: FilecoinSignedMessage
    ) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            provider
                .submitTransaction(signedMessage: signedMessage)
                .map(\.hash)
                .eraseToAnyPublisher()
        }
    }
}
