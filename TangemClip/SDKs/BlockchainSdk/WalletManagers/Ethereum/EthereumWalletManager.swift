//
//  EthereumWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Combine
import Moya

public enum ETHError: String, Error, LocalizedError {
    case failedToParseTxCount = "eth_tx_count_parse_error"
    case failedToParseBalance = "eth_balance_parse_error"
    case failedToParseGasLimit
    case notValidEthereumValue
    case unsupportedFeature
    
    public var errorDescription: String? {
        switch self {
        case .failedToParseGasLimit:
            return rawValue
        default:
            return rawValue.localized
        }
    }
}

class EthereumWalletManager: WalletManager {
    var networkService: EthereumNetworkService!
    
    private var findTokensSubscription: AnyCancellable? = nil
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address, tokens: cardTokens)
            .sink(receiveCompletion: {[unowned self] completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self.wallet.amounts = [:]
                    completion(.failure(error))
                }
            }, receiveValue: { [unowned self] response in
                self.updateWallet(with: response)
                completion(.success(()))
            })
    }
    
    private func updateWallet(with response: EthereumInfoResponse) {
        wallet.add(coinValue: response.balance)
        for tokenBalance in response.tokenBalances {
            wallet.add(tokenValue: tokenBalance.value, for: tokenBalance.key)
        }
    }
}


extension EthereumWalletManager: ThenProcessable { }

extension EthereumWalletManager: TokenFinder {
    func findErc20Tokens(completion: @escaping (Result<Bool, Error>)-> Void) {
        findTokensSubscription?.cancel()
        findTokensSubscription = networkService
            .findErc20Tokens(address: wallet.address)
            .sink(receiveCompletion: { subscriptionCompletion in
                if case let .failure(error) = subscriptionCompletion {
                    completion(.failure(error))
                    return
                }
            }, receiveValue: {[unowned self] blockchairTokens in
                if blockchairTokens.isEmpty {
                    completion(.success(false))
                    return
                }
                
                var tokensAdded = false
                blockchairTokens.forEach { blockchairToken in
                    let token = Token(blockchairToken, blockchain: self.wallet.blockchain)
                    if !self.cardTokens.contains(token) {
                        self.cardTokens.append(token)
                        let balanceValue = Decimal(blockchairToken.balance) ?? 0
                        let balanceWeiValue = balanceValue / pow(Decimal(10), blockchairToken.decimals)
                        self.wallet.add(tokenValue: balanceWeiValue, for: token)
                        tokensAdded = true
                    }
                }
                
                completion(.success(tokensAdded))
            })
    }
}
