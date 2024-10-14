//
//  PolkadotJsonRpcProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 27.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya

class PolkadotJsonRpcProvider: HostProvider {
    var host: String { node.url.hostOrUnknown }

    private let node: NodeInfo
    private let provider: NetworkProvider<PolkadotTarget>
    
    init(node: NodeInfo, configuration: NetworkProviderConfiguration) {
        self.node = node
        provider = NetworkProvider<PolkadotTarget>(configuration: configuration)
    }
    
    func storage(key: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .storage(key: key))
    }
    
    func blockhash(_ type: PolkadotBlockhashType) -> AnyPublisher<String, Error> {
        requestPublisher(for: .blockhash(type: type))
    }
    
    func header(_ blockhash: String) -> AnyPublisher<PolkadotHeader, Error> {
        requestPublisher(for: .header(hash: blockhash))
    }
    
    func accountNextIndex(_ address: String) -> AnyPublisher<UInt64, Error> {
        requestPublisher(for: .accountNextIndex(address: address))
    }
    
    func queryInfo(_ extrinsic: String) -> AnyPublisher<PolkadotQueriedInfo, Error> {
        requestPublisher(for: .queryInfo(extrinsic: extrinsic))
    }
    
    func runtimeVersion() -> AnyPublisher<PolkadotRuntimeVersion, Error> {
        requestPublisher(for: .runtimeVersion(url: node.url))
    }
    
    func submitExtrinsic(_ extrinsic: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .submitExtrinsic(extrinsic: extrinsic))
    }
    
    private func requestPublisher<T: Codable>(for target: PolkadotTarget.Target) -> AnyPublisher<T, Error> {
        return provider.requestPublisher(PolkadotTarget(node: node, target: target))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(PolkadotJsonRpcResponse<T>.self)
            .tryMap {
                if let error = $0.error?.error {
                    throw error
                }

                guard let result = $0.result else {
                    throw WalletError.empty
                }

                return result
            }
            .eraseToAnyPublisher()
    }
}
