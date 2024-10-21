//
//  PolkadotNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 01.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import ScaleCodec
import Sodium

class PolkadotNetworkService: MultiNetworkProvider {
    var currentProviderIndex: Int = 0
    let providers: [PolkadotJsonRpcProvider]
    
    private let network: PolkadotNetwork
    private let codec = SCALE.default
    
    init(providers: [PolkadotJsonRpcProvider], network: PolkadotNetwork) {
        self.providers = providers
        self.network = network
    }
    
    func getInfo(for address: String) -> AnyPublisher<BigUInt, Error> {
        providerPublisher { provider in
            Just(())
                .tryMap { [weak self] _ -> Data in
                    guard let self = self else {
                        throw WalletError.empty
                    }
                    return try self.storageKey(forAddress: address)
                }
                .flatMap { key -> AnyPublisher<String, Error> in
                    return provider.storage(key: key.hexString.addHexPrefix())
                }
                .tryMap { [weak self] storage -> PolkadotAccountInfo in
                    guard let self = self else {
                        throw WalletError.empty
                    }
                    return try self.codec.decode(PolkadotAccountInfo.self, from: Data(hexString: storage))
                }
                .map(\.data.free)
                .tryCatch { error -> AnyPublisher<BigUInt, Error> in
                    if let walletError = error as? WalletError {
                        switch walletError {
                        case .empty:
                            return .justWithError(output: 0)
                        default:
                            break
                        }
                    }
                    
                    throw error
                }
                .eraseToAnyPublisher()
        }
    }
    
    func blockchainMeta(for address: String) -> AnyPublisher<PolkadotBlockchainMeta, Error> {
        providerPublisher { provider in
            let latestBlockPublisher: AnyPublisher<(String, UInt64), Error> = provider.blockhash(.latest)
                .flatMap { [weak self] latestBlockHash -> AnyPublisher<(String, UInt64), Error> in
                    guard 
                        let self = self,
                        let provider = self.provider
                    else {
                        return .emptyFail
                    }
                    
                    let latestBlockHashPublisher = Just(latestBlockHash).setFailureType(to: Error.self)
                    let latestBlockNumberPublisher = provider
                        .header(latestBlockHash)
                        .map(\.number)
                        .tryMap { UInt64($0.removeHexPrefix(), radix: 16) ?? 0 } // TODO: BigInt

                    return Publishers.Zip(latestBlockHashPublisher, latestBlockNumberPublisher).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
            
            
            return Publishers.Zip4(
                provider.blockhash(.genesis), 
                latestBlockPublisher,
                provider.accountNextIndex(address),
                provider.runtimeVersion()
            ).map { genesisHash, latestBlockInfo, nextIndex, runtimeVersion in
                PolkadotBlockchainMeta(
                    specVersion: runtimeVersion.specVersion,
                    transactionVersion: runtimeVersion.transactionVersion,
                    genesisHash: genesisHash,
                    blockHash: latestBlockInfo.0,
                    nonce: nextIndex,
                    era: .init(blockNumber: latestBlockInfo.1, period: 128) // Should be power of two
                )
            }
            .eraseToAnyPublisher()
        }
    }
    
    func fee(for extrinsic: Data) -> AnyPublisher<UInt64, Error> {
        providerPublisher { provider in
            provider.queryInfo(extrinsic.hexString.addHexPrefix())
                .tryMap {
                    guard let fee = UInt64($0.partialFee) else {
                        throw WalletError.failedToGetFee
                    }
                    return fee
                }
                .eraseToAnyPublisher()
        }
    }
    
    func submitExtrinsic(data: Data) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            provider.submitExtrinsic(data.hexString.addHexPrefix())
        }
    }
    
    private func storageKey(forAddress address: String) throws -> Data {
        guard
            let address = PolkadotAddress(string: address, network: network),
            let addressBytes = address.bytes(raw: true),
            // TODO: Use extension from Data+
            let addressHash = Sodium().genericHash.hash(message: addressBytes.bytes, outputLength: 16)
        else {
            throw WalletError.empty
        }
        
        // XXHash of "System" module and "Account" storage item.
        let moduleNameHash = Data(hexString: "26aa394eea5630e07c48ae0c9558cef7")
        let storageNameKeyHash = Data(hexString: "b99d880ec681799c0cf30e8886371da9")
        
        let key = moduleNameHash + storageNameKeyHash + addressHash + addressBytes
        return key
    }
}
