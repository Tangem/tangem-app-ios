//
//  WalletConnectTransactionBuilder.swift
//  Tangem
//
//  Created by Andrew Son on 17/05/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import WalletConnectSwift

class WalletConnectTransactionHandler: TangemWalletConnectRequestHandler {
    unowned var delegate: WalletConnectHandlerDelegate?
    unowned var dataSource: WalletConnectHandlerDataSource?

    var action: WalletConnectAction { fatalError("Subclass must implement") }

    var bag: Set<AnyCancellable> = []

    init(delegate: WalletConnectHandlerDelegate, dataSource: WalletConnectHandlerDataSource) {
        self.delegate = delegate
        self.dataSource = dataSource
    }

    func handle(request: Request) {
        fatalError("Subclass must implement")
    }

    func handleTransaction(from request: Request) -> (session: WalletConnectSession, tx: WalletConnectEthTransaction)? {
        do {
            let transaction = try request.parameter(of: WalletConnectEthTransaction.self, at: 0)

            guard let session = dataSource?.session(for: request) else {
                delegate?.sendReject(for: request, with: WalletConnectServiceError.sessionNotFound, for: action)
                return nil
            }

            return (session, transaction)
        } catch {
            delegate?.sendInvalid(request)
            return nil
        }
    }

    func sendReject(for request: Request, error: Error?) {
        delegate?.sendReject(for: request, with: error ?? WalletConnectServiceError.cancelled, for: action)
        bag = []
    }

    func buildTx(in session: WalletConnectSession, _ transaction: WalletConnectEthTransaction) -> AnyPublisher<(WalletModel, Transaction), Error> {
        let wallet = session.wallet
        let blockchain = wallet.blockchain
        let walletModel = dataSource?.cardModel.walletModels.first(where: {
            $0.wallet.blockchain == wallet.blockchain &&
                $0.wallet.address.lowercased() == transaction.from.lowercased()
        })

        guard let walletModel else {
            let error = WalletConnectServiceError.failedToBuildTx(code: .wrongAddress)
            AppLog.shared.error(error)
            return .anyFail(error: error)
        }

        guard let gasLoader = walletModel.walletManager as? EthereumGasLoader else {
            let error = WalletConnectServiceError.failedToBuildTx(code: .noWalletManager)
            AppLog.shared.error(error)
            return .anyFail(error: error)
        }

        let rawValue = transaction.value ?? "0x0"
        guard let value = EthereumUtils.parseEthereumDecimal(rawValue, decimalsCount: blockchain.decimalCount) else {
            let error = ETHError.failedToParseBalance(value: rawValue, address: "", decimals: blockchain.decimalCount)
            AppLog.shared.error(error)
            return .anyFail(error: error)
        }

        let valueAmount = Amount(with: blockchain, type: .coin, value: value)

        let dappGasLimit = transaction.gas?.hexToInteger ?? transaction.gasLimit?.hexToInteger
        let dappGasLimitPublisher: AnyPublisher<Int, Error>? = dappGasLimit.map { .justWithError(output: $0) }

        let gasPricePublisher = getGasPrice(for: valueAmount, tx: transaction, txSender: gasLoader, decimalCount: blockchain.decimalCount)
        let gasLimitPublisher = dappGasLimitPublisher ?? getGasLimit(for: valueAmount, destination: transaction.to, data: transaction.data, txSender: gasLoader)

        let walletUpdatePublisher = walletModel
            .$state
            .setFailureType(to: Error.self)
            .tryMap { state -> WalletModel.State in
                switch state {
                case .failed(let error):
                    throw error
                case .noAccount(let message):
                    throw message
                default:
                    return state
                }
            }
            .filter { $0 == .idle }

        walletModel.update(silent: false)


        // This zip attempting to load gas price and update wallet balance.
        // In some cases (ex. when swapping currencies on OpenSea) dApp didn't send gasPrice, that why we need to load this data from blockchain
        // Also we must identify that wallet failed to update balance.
        // If we couldn't get gasPrice and can't update wallet balance reject message will be send to dApp
        return Publishers.Zip3(gasPricePublisher, gasLimitPublisher, walletUpdatePublisher)
            .flatMap { (gasPrice, gasLimit, state) -> AnyPublisher<Transaction, Error> in
                Future { promise in
                    let gasAmount = Amount(with: blockchain, type: .coin, value: Decimal(gasLimit * gasPrice) / blockchain.decimalValue)
                    let totalAmount = valueAmount + gasAmount
                    let balance = walletModel.wallet.amounts[.coin] ?? .zeroCoin(for: blockchain)
                    let dApp = session.session.dAppInfo
                    let message: String = {

                        var m = ""
                        m += Localization.walletConnectCreateTxMessage(
                            dApp.peerMeta.name,
                            dApp.peerMeta.url.absoluteString,
                            valueAmount.description,
                            gasAmount.description,
                            totalAmount.description,
                            walletModel.getBalance(for: .coin))
                        if (balance < totalAmount) {
                            m += "\n\n" + Localization.walletConnectCreateTxNotEnoughFunds
                        }
                        return m
                    }()
                    let alert = WalletConnectUIBuilder.makeAlert(for: .sendTx, message: message, onAcceptAction: {

                        do {
                            var tx = try walletModel.walletManager.createTransaction(amount: valueAmount,
                                                                                     fee: gasAmount,
                                                                                     destinationAddress: transaction.to,
                                                                                     sourceAddress: transaction.from)
                            let contractDataString = transaction.data.drop0xPrefix
                            let wcTxData = Data(hexString: String(contractDataString))
                            tx.params = EthereumTransactionParams(data: wcTxData, gasLimit: gasLimit, nonce: transaction.nonce?.hexToInteger)
                            promise(.success(tx))
                        } catch {
                            promise(.failure(error))
                        }
                    }, isAcceptEnabled: (balance >= totalAmount), onReject: {
                        promise(.failure(WalletConnectServiceError.cancelled))
                    })

                    AppPresenter.shared.show(alert)
                }
                .eraseToAnyPublisher()
            }
            .map { (walletModel, $0) }
            .eraseToAnyPublisher()
    }

    private func getGasPrice(for amount: Amount, tx: WalletConnectEthTransaction, txSender: EthereumGasLoader, decimalCount: Int) -> AnyPublisher<Int, Error> {
        guard
            let gasPriceString = tx.gasPrice,
            let gasPrice = gasPriceString.hexToInteger
        else {
            return txSender.getGasPrice()
                .flatMap { (gasPrice) -> AnyPublisher<Int, Error> in
                    .justWithError(output: Int(gasPrice))
                }
                .eraseToAnyPublisher()
        }

        return .justWithError(output: gasPrice)
    }

    private func getGasLimit(for amount: Amount, destination: String, data: String?, txSender: EthereumGasLoader) -> AnyPublisher<Int, Error> {
        return txSender.getGasLimit(amount: amount, destination: destination)
            .map { Int($0) }
            .replaceError(with: 600000) // Fixed high gaslimit
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
