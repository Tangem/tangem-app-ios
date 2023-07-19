//
//  SignTransactionHandler.swift
//  Tangem
//
//  Created by Alexander Osokin on 02.04.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import BlockchainSdk
import Combine

class SignTransactionHandler: WalletConnectTransactionHandler {
    private var signer: EthereumTransactionSigner!

    override var action: WalletConnectAction { .signTransaction }

    override func handle(request: Request) {
        guard let result = handleTransaction(from: request) else { return }

        askToSign(in: result.session, request: request, ethTransaction: result.tx)
    }

    private func askToSign(in session: WalletConnectSession, request: Request, ethTransaction: WalletConnectEthTransaction) {
        buildTx(in: session, ethTransaction)
            .flatMap { [weak self] buildResponse -> AnyPublisher<String, Error> in
                guard let cardModel = self?.dataSource?.cardModel else {
                    return .anyFail(error: WalletConnectServiceError.deallocated)
                }

                let ethWalletModel = buildResponse.0
                let tx = buildResponse.1

                guard let txSigner = ethWalletModel.ethereumTransactionSigner else {
                    return .anyFail(error: WalletConnectServiceError.failedToFindSigner)
                }

                self?.signer = txSigner

                return txSigner.sign(tx, signer: cardModel.signer)
            }
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.sendReject(for: request, error: error)
                case .finished:
                    break
                }
                self?.bag = []
            } receiveValue: { [weak self] tx in
                self?.delegate?.send(.signature(tx, for: request), for: .signTransaction)
            }
            .store(in: &bag)
    }
}
