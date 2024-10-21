//
// SuiBalanceFetcher.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 16.09.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SuiBalanceFetcher {
    typealias RequestPublisherBuilder = (_ address: String, _ coin: String, _ cursor: String?) -> AnyPublisher<SuiGetCoins, Error>
    private var cancellable = Set<AnyCancellable>()
    private var coins = Set<SuiGetCoins.Coin>()
    private var subject = PassthroughSubject<Result<[SuiGetCoins.Coin], Error>, Never>()
    private var requestPublisherBuilder: RequestPublisherBuilder?
    
    var publisher: AnyPublisher<Result<[SuiGetCoins.Coin], Error>, Never> {
        subject.eraseToAnyPublisher()
    }
    
    func setupRequestPublisherBuilder(_ requestPublisherBuilder:  @escaping RequestPublisherBuilder) -> Self {
        self.requestPublisherBuilder = requestPublisherBuilder
        return self
    }
    
    func fetchBalance(address: String, coin: String, cursor: String?) -> AnyPublisher<Result<[SuiGetCoins.Coin], Error>, Never> {
        cancel()
        clear()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let requestPublisher = self?.requestPublisherBuilder?(address, coin, cursor) else {
                self?.subject.send(.failure(WalletError.empty))
                return
            }
            
            self?.load(address: address, coin: coin, cursor: cursor, requestPublisher: requestPublisher)
        }
        
        return publisher
    }
    
    func cancel() {
        cancellable.forEach({ $0.cancel() })
        cancellable.removeAll()
    }
    
    func clear() {
        coins.removeAll()
    }
    
    private func load(address: String, coin: String, cursor: String?, requestPublisher: AnyPublisher<SuiGetCoins, Error>) {
        requestPublisher
            .sink { [weak self] completionSubscriptions in
                if case .failure = completionSubscriptions {
                    self?.subject.send(.failure(WalletError.empty))
                    self?.clear()
                }
            } receiveValue: { [weak self] response in
                
                guard let self else {
                    return
                }
                
                coins.formUnion(response.data)
                
                if response.hasNextPage {
                    guard let nextPublisher = self.requestPublisherBuilder?(address, coin, response.nextCursor) else {
                        self.subject.send(.failure(WalletError.empty))
                        self.clear()
                        return
                    }
                    
                    self.load(address: address, coin: coin, cursor: response.nextCursor, requestPublisher: nextPublisher)
                } else {
                    self.subject.send(.success(self.coins.asArray))
                    self.clear()
                }
            }
            .store(in: &cancellable)
    }
}
