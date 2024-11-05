//
//  ElectrumNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class ElectrumNetworkProvider: MultiNetworkProvider {
    let providers: [ElectrumWebSocketProvider]
    var currentProviderIndex: Int = 0

    init(providers: [ElectrumWebSocketProvider]) {
        self.providers = providers
    }

    func getAddressInfo(identifier: ElectrumWebSocketProvider.Identifier) -> AnyPublisher<ElectrumAddressInfo, Error> {
        providerPublisher { provider in
            Future.async {
                async let balance = provider.getBalance(identifier: identifier)
                async let unspents = provider.getUnspents(identifier: identifier)

                return try await ElectrumAddressInfo(
                    balance: Decimal(balance.confirmed),
                    outputs: unspents.map { unspent in
                        ElectrumUTXO(
                            position: unspent.txPos,
                            hash: unspent.txHash,
                            value: unspent.value,
                            height: unspent.height
                        )
                    }
                )
            }
            .eraseToAnyPublisher()
        }
    }

    func estimateFee() -> AnyPublisher<Decimal, Error> {
        providerPublisher { provider in
            Future.async {
                try await provider.estimateFee(block: 10)
            }
            .eraseToAnyPublisher()
        }
    }

    func send(transactionHex: String) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            Future.async {
                try await provider.send(transactionHex: transactionHex)
            }
            .eraseToAnyPublisher()
        }
    }
}
