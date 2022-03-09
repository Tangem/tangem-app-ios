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
    unowned var assembly: Assembly
    unowned var scannedCardsRepo: ScannedCardsRepository
    unowned var delegate: WalletConnectHandlerDelegate?
    unowned var dataSource: WalletConnectHandlerDataSource?
    
    let signer: TangemSigner
    
    var action: WalletConnectAction { fatalError("Subclass must implement") }
    
    var bag: Set<AnyCancellable> = []
    
    init(signer: TangemSigner, delegate: WalletConnectHandlerDelegate, dataSource: WalletConnectHandlerDataSource, assembly: Assembly, scannedCardsRepo: ScannedCardsRepository) {
        self.assembly = assembly
        self.scannedCardsRepo = scannedCardsRepo
        self.signer = signer
        self.delegate = delegate
        self.dataSource = dataSource
    }
    
    func handle(request: Request) {
        fatalError("Subclass must implement")
    }
    
    func handleTransaction(from request: Request) -> (session: WalletConnectSession, tx: WalletConnectEthTransaction)? {
        do {
            let transaction = try request.parameter(of: WalletConnectEthTransaction.self, at: 0)
            
            guard let session = dataSource?.session(for: request, address: transaction.from) else {
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
        
        guard let card = scannedCardsRepo.cards[wallet.cid] else {
            return .anyFail(error: WalletConnectServiceError.cardNotFound)
        }
        
        let blockchain = wallet.blockchain
        let walletModels = assembly.makeWalletModels(from: card, blockchains: [blockchain])
        
        guard let walletModel = walletModels.first(where: { $0.wallet.address.lowercased() == transaction.from.lowercased() }) else {
            let error = WalletConnectServiceError.failedToBuildTx(code: .wrongAddress)
            Analytics.log(error: error)
            return .anyFail(error: error)
        }
        
        guard let gasLoader = walletModel.walletManager as? EthereumGasLoader else {
            let error = WalletConnectServiceError.failedToBuildTx(code: .noWalletManager)
            Analytics.log(error: error)
            return .anyFail(error: error)
        }
        
        guard let value = try? EthereumUtils.parseEthereumDecimal(transaction.value ?? "0x0", decimalsCount: blockchain.decimalCount) else {
            let error = WalletConnectServiceError.failedToBuildTx(code: .noValue)
            Analytics.log(error: error)
            return .anyFail(error: error)
        }
        
        let valueAmount = Amount(with: blockchain, type: .coin, value: value)
        
        let gasLimit = transaction.gas?.hexToInteger ?? transaction.gasLimit?.hexToInteger ?? 300000 //Set high gasLimit if not provided

        let gasPricePublisher = getGasPrice(for: valueAmount, tx: transaction, txSender: gasLoader, decimalCount: blockchain.decimalCount)
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
        
        walletModel.update()

        
        // This zip attempting to load gas price and update wallet balance.
        // In some cases (ex. when swapping currencies on OpenSea) dApp didn't send gasPrice, that why we need to load this data from blockchain
        // Also we must identify that wallet failed to update balance.
        // If we couldn't get gasPrice and can't update wallet balance reject message will be send to dApp
        return Publishers.Zip(gasPricePublisher, walletUpdatePublisher)
            .flatMap { (gasPrice, state) -> AnyPublisher<Transaction, Error> in
                Future { [weak self] promise in
                    let gasAmount = Amount(with: blockchain, type: .coin, value: Decimal(gasLimit * gasPrice) / blockchain.decimalValue)
                    let totalAmount = valueAmount + gasAmount
                    let balance = walletModel.wallet.amounts[.coin] ?? .zeroCoin(for: blockchain)
                    let dApp = session.session.dAppInfo
                    let message: String = {
                        
                        var m = ""
                        m += String(format: "wallet_connect_create_tx_message".localized,
                                    AppCardIdFormatter(cid: wallet.cid).formatted(),
                                    dApp.peerMeta.name,
                                    dApp.peerMeta.url.absoluteString,
                                    valueAmount.description,
                                    gasAmount.description,
                                    totalAmount.description,
                                    walletModel.getBalance(for: .coin))
                        if (balance < totalAmount) {
                            m += "wallet_connect_create_tx_not_enough_funds".localized
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
                    self?.presentOnMain(vc: alert)
                }
                .eraseToAnyPublisher()
            }
            .map { (walletModel, $0) }
            .eraseToAnyPublisher()
    }
    
    func presentOnMain(vc: UIViewController, delay: Double = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIApplication.modalFromTop(vc)
        }
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
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
