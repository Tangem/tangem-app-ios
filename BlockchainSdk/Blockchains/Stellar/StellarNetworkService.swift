//
//  StellarNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
class StellarNetworkService: MultiNetworkProvider {
    var currentProviderIndex: Int = 0
    let providers: [StellarNetworkProvider]
    
    init(providers: [StellarNetworkProvider]) {
        self.providers = providers
    }
    
    public func send(transaction: String) -> AnyPublisher<String, Error> {
        providerPublisher {
            $0.send(transaction: transaction)
        }
    }
    
    public func checkTargetAccount(address: String, token: Token?) -> AnyPublisher<StellarTargetAccountResponse, Error> {
        providerPublisher {
            $0.checkTargetAccount(address: address, token: token)
        }
    }
    
    public func getInfo(accountId: String, isAsset: Bool) -> AnyPublisher<StellarResponse, Error> {
        providerPublisher {
            $0.getInfo(accountId: accountId, isAsset: isAsset)
        }
    }
    
    public func getFee() -> AnyPublisher<[Amount], Error> {
        providerPublisher {
            $0.getFee()
        }
    }
    
    public func getSignatureCount(accountId: String) -> AnyPublisher<Int, Error> {
        providerPublisher {
            $0.getSignatureCount(accountId: accountId)
        }
    }
}
