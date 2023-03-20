//
//  SendTransactionHandler.swift
//  Tangem
//
//  Created by Andrew Son on 10/04/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import BlockchainSdk
import TangemSdk
import Combine

class SendTransactionHandler: WalletConnectTransactionHandler {
    override var action: WalletConnectAction { .sendTransaction }

    override func handle(request: Request) {
        guard let result = handleTransaction(from: request) else { return }

        askToMakeTx(in: result.session, for: request, ethTx: result.tx)
    }

    private func askToMakeTx(in session: WalletConnectSession, for request: Request, ethTx: WalletConnectEthTransaction) {
        buildTx(in: session, ethTx)
            .flatMap { [weak self] buildResult -> AnyPublisher<WalletModel, Error> in
                guard let cardModel = self?.dataSource?.cardModel else {
                    return .anyFail(error: WalletConnectServiceError.deallocated)
                }

                let ethWalletModel = buildResult.0
                let tx = buildResult.1
                return ethWalletModel.walletManager.send(tx, signer: cardModel.signer)
                    .map { _ in ethWalletModel }
                    .eraseToAnyPublisher()
            }
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.sendReject(for: request, error: error)
                case .finished:
                    break
                }
                self?.bag = []
            } receiveValue: { [weak self] ethWalletModel in
                guard let self = self else { return }

                let vc = WalletConnectUIBuilder.makeAlert(for: .success, message: Localization.sendTransactionSuccess, onAcceptAction: {})
                AppPresenter.shared.show(vc)

                guard
                    let sendedTx = ethWalletModel.wallet.transactions.last,
                    let txHash = sendedTx.hash
                else {
                    self.sendReject(for: request, error: WalletConnectServiceError.txNotFound)
                    return
                }

                Analytics.log(.transactionSentBasic, params: [.commonSource: .transactionSourceWalletConnect])

                self.delegate?.send(try! Response(url: request.url, value: txHash, id: request.id!), for: self.action)
            }
            .store(in: &bag)
    }
}
