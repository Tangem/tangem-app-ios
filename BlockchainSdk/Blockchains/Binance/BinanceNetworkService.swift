//
//  BinanceNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 15.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BinanceChain
import Combine
import TangemNetworkUtils

class BinanceNetworkService {
    let binance: BinanceChain
    let testnet: Bool

    var host: String {
        URL(string: endpoint.rawValue)!.hostOrUnknown
    }

    private let endpoint: BinanceChain.Endpoint

    init(isTestNet: Bool) {
        testnet = isTestNet
        endpoint = isTestNet ? .testnet : .mainnet
        binance = BinanceChain(endpoint: endpoint)
    }

    func getInfo(address: String) -> AnyPublisher<BinanceInfoResponse, Error> {
        let future = Future<BinanceInfoResponse, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(WalletError.empty))
                return
            }

            binance.account(address: address) { response in
                if let error = response.getError() {
                    promise(.failure(error))
                    return
                }

                let balances = response.account.balances.reduce(into: [:]) { result, balance in
                    result[balance.symbol] = Decimal(balance.free)
                }

                let accountNumber = response.account.accountNumber
                let sequence = response.account.sequence
                let info = BinanceInfoResponse(balances: balances, accountNumber: accountNumber, sequence: sequence)
                promise(.success(info))
            }
        }
        return AnyPublisher(future)
    }

    func getFee() -> AnyPublisher<String, Error> {
        let future = Future<String, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(WalletError.empty))
                return
            }

            binance.fees { response in
                if let error = response.getError() {
                    promise(.failure(error))
                    return
                }

                let fees: [String] = response.fees.compactMap { fee -> String? in
                    return fee.fixedFeeParams?.fee
                }

                guard let feeString = fees.first,
                      let decimalfee = Decimal(string: feeString) else {
                    promise(.failure("Failed to load fee"))
                    return
                }
                let blockchain = Blockchain.binance(testnet: self.testnet)
                let convertedFee = (decimalfee / blockchain.decimalValue).rounded(blockchain: blockchain)
                let fee = "\(convertedFee)"
                promise(.success(fee))
            }
        }
        return AnyPublisher(future)
    }

    func send(transaction: Message) -> AnyPublisher<BinanceChain.Response, Error> {
        let future = Future<BinanceChain.Response, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(WalletError.empty))
                return
            }

            binance.broadcast(message: transaction, sync: true) { response in
                if let error = response.getError() {
                    promise(.failure(error))
                    return
                }

                promise(.success(response))
            }
        }
        return AnyPublisher(future)
    }
}

extension BinanceChain.Response {
    func getError() -> Error? {
        if error?.localizedDescription.lowercased().contains("account not found") ?? false {
            return WalletError.noAccount(message: Localization.noAccountSendToCreate, amountToCreate: 0)
        } else {
            return error
        }
    }
}

struct BinanceInfoResponse {
    let balances: [String: Decimal]
    let accountNumber: Int
    let sequence: Int
}
