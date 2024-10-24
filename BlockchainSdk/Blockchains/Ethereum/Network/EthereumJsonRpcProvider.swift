//
//  EthereumJsonRpcProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 01/05/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt
import Moya

class EthereumJsonRpcProvider: HostProvider {
    let url: URL
    
    var host: String {
        url.hostOrUnknown
    }
    
    private let provider: NetworkProvider<EthereumTarget>

    init(url: URL, configuration: NetworkProviderConfiguration) {
        self.url = url
        provider = NetworkProvider<EthereumTarget>(configuration: configuration)
    }
    
    func call(contractAddress: String, encodedData: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .call(params: .init(to: contractAddress, data: encodedData)))
    }
    
    func getBalance(for address: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .balance(address: address))
    }
    
    func getTxCount(for address: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .transactions(address: address))
    }
    
    func getPendingTxCount(for address: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .pending(address: address))
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .send(transaction: transaction))
    }
    
    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<String, Error> {
        requestPublisher(for: .gasLimit(params: .init(to: to, from: from, value: value, data: data)))
    }
    
    func getGasPrice() -> AnyPublisher<String, Error> {
        requestPublisher(for: .gasPrice)
    }

    func getPriorityFee() -> AnyPublisher<String, Error> {
        requestPublisher(for: .priorityFee)
    }

    func getFeeHistory() -> AnyPublisher<EthereumFeeHistoryResponse, Error> {
        requestPublisher(for: .feeHistory)
    }

    private func requestPublisher<Result: Decodable>(for targetType: EthereumTarget.EthereumTargetType) -> AnyPublisher<Result, Error> {
        let target = EthereumTarget(targetType: targetType, baseURL: url)

        return provider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(JSONRPC.Response<Result, JSONRPC.APIError>.self)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }
}
