//
//  XRPNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

protocol XRPNetworkServiceType {
    var host: String { get }
    func getFee() -> AnyPublisher<XRPFeeResponse, Error>
    func send(blob: String) -> AnyPublisher<String, Error>
    func getInfo(account: String) -> AnyPublisher<XrpInfoResponse, Error>
    func checkAccountCreated(account: String) -> AnyPublisher<Bool, Error>
}

class XRPNetworkService: MultiNetworkProvider, XRPNetworkServiceType {
    let providers: [XRPNetworkProvider]
    var currentProviderIndex: Int = 0
    
    init(providers: [XRPNetworkProvider]) {
        self.providers = providers
    }
    
    func getInfo(account: String) -> AnyPublisher<XrpInfoResponse, Error> {
        providerPublisher { provider in
            provider.getInfo(account: account)
        }
    }
    
    func send(blob: String) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            provider.send(blob: blob)
        }
    }
    
    func getFee() -> AnyPublisher<XRPFeeResponse, Error> {
        providerPublisher { provider in
            provider.getFee()
        }
    }
    
    func checkAccountCreated(account: String) -> AnyPublisher<Bool, Error> {
        providerPublisher { provider in
            provider.checkAccountCreated(account: account)
        }
    }
}
