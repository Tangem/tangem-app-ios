//
//  Walletmanager.swift
//  blockchainSdk
//
//  Created by Alexander Osokin on 04.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine
import RxSwift

public class WalletManager<TWallet: Wallet> {
    var cardId: String!
    var wallet: Variable<TWallet>!
    var error: PublishSubject<Error> = .init()
    func update() {}
}

@available(iOS 13.0, *)
public protocol TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Bool, Error>
    func getFee(amount: Amount, source: String, destination: String) -> AnyPublisher<[Amount], Error>
}

@available(iOS 13.0, *)
public protocol TransactionSigner {
    func sign(hashes: [Data], cardId: String, completion: @escaping (Result<SignResponse, SessionError>) -> Void)
    func sign(hashes: [Data], cardId: String) -> AnyPublisher<SignResponse, Error>
}
