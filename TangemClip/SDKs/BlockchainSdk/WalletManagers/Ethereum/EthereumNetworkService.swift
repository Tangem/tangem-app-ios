//
//  EthereumNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 18.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import SwiftyJSON
//import web3swift
import BigInt

class EthereumNetworkService: MultiNetworkProvider<EthereumJsonRpcProvider> {
    private let blockchain: Blockchain
    private let decimals: Int
    private let blockchairProvider: BlockchairNetworkProvider?
    
    init(blockchain: Blockchain, providers: [EthereumJsonRpcProvider], blockchairProvider: BlockchairNetworkProvider?) {
        self.blockchain = blockchain
        self.decimals = blockchain.decimalCount
        self.blockchairProvider = blockchairProvider
        super.init(providers: providers)
    }
    
    func getInfo(address: String, tokens: [Token]) -> AnyPublisher<EthereumInfoResponse, Error> {
        Publishers.Zip(
            getBalance(address),
            getTokensBalance(address, tokens: tokens)
        )
        .map { (result: (Decimal, [Token: Decimal])) in
            EthereumInfoResponse(balance: result.0, tokenBalances: result.1)
        }
        .eraseToAnyPublisher()
    }
    
    func getTokensBalance(_ address: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error> {
        tokens
            .publisher
            .setFailureType(to: Error.self)
            .flatMap {[unowned self] token in
                self.providerPublisher { provider in
                    provider.getTokenBalance(for: address, contractAddress: token.contractAddress)
                        .tryMap { resp -> Decimal in
                            try EthereumUtils.parseEthereumDecimal(resp.result ?? "", decimalsCount: token.decimalCount)
                        }
                        .map { (token, $0) }
                        .eraseToAnyPublisher()
                }
            }
            .collect()
            .map { $0.reduce(into: [Token: Decimal]()) { $0[$1.0] = $1.1 }}
            .eraseToAnyPublisher()
    }
    
    func findErc20Tokens(address: String) -> AnyPublisher<[BlockchairToken], Error> {
        guard let blockchairProvider = blockchairProvider else {
            return Fail(error: ETHError.unsupportedFeature).eraseToAnyPublisher()
        }
        
        return blockchairProvider.findErc20Tokens(address: address)
    }
    
	// MARK: - Private functions
    
    private func tokenData(address: String, tokens: [Token]) -> AnyPublisher<(Decimal,[Token:Decimal]), Error> {
        Publishers.Zip(getBalance(address),
                              getTokensBalance(address, tokens: tokens))
            .eraseToAnyPublisher()
    }
    
    private func coinData(address: String) -> AnyPublisher<Decimal, Error> {
        getBalance(address)
            .eraseToAnyPublisher()
    }
    
    private func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> {
        providerPublisher { provider in
            provider.getBalance(for: address)
                .tryMap {
                    try EthereumUtils.parseEthereumDecimal($0.result ?? "", decimalsCount: self.decimals)
                }
                .eraseToAnyPublisher()
        }
    }
    
    private func getTokenBalance(_ address: String, contractAddress: String, tokenDecimals: Int) -> AnyPublisher<Decimal, Error> {
        providerPublisher { provider in
            provider.getTokenBalance(for: address, contractAddress: contractAddress)
                .tryMap {
                    try EthereumUtils.parseEthereumDecimal($0.result ?? "", decimalsCount: tokenDecimals)
                }
                .eraseToAnyPublisher()
        }
    }
}
