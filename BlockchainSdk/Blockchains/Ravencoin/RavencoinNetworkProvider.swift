//
//  RavencoinNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

/// Documentations:
/// https://github.com/RavenDevKit/insight-api
/// https://github.com/RavenProject/Ravencoin/blob/master/doc/REST-interface.md
class RavencoinNetworkProvider: HostProvider {
    let host: String
    let provider: NetworkProvider<RavencoinTarget>

    private var decimalValue: Decimal { Blockchain.ravencoin(testnet: false).decimalValue }

    init(host: String, provider: NetworkProvider<RavencoinTarget>) {
        self.host = host
        self.provider = provider
    }
}

// MARK: - BitcoinNetworkProvider

extension RavencoinNetworkProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool { false }

    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        Publishers.Zip(getWalletInfo(address: address), getUTXO(address: address))
            .flatMap { [weak self] wallet, outputs -> AnyPublisher<BitcoinResponse, Error> in
                guard let self else {
                    return .anyFail(error: WalletError.empty)
                }

                let hasUnconfirmed = wallet.unconfirmedTxApperances != 0
                if hasUnconfirmed {
                    return getTransactions(request: .init(address: address))
                        .map { transactions -> BitcoinResponse in
                            self.mapToBitcoinResponse(
                                wallet: wallet,
                                outputs: outputs,
                                transactions: transactions
                            )
                        }
                        .eraseToAnyPublisher()
                }

                let response = mapToBitcoinResponse(wallet: wallet, outputs: outputs, transactions: [])
                return .justWithError(output: response)
            }
            .eraseToAnyPublisher()
    }

    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        getFeeRatePerByte(blocks: 10)
            .tryMap { [weak self] perByte in
                guard let self else {
                    throw BlockchainSdkError.failedToLoadFee
                }

                // Increase rate just in case
                let perByte = perByte * 1.1
                let satoshi = perByte * decimalValue
                let minRate = satoshi
                let normalRate = satoshi * 12 / 10
                let priorityRate = satoshi * 15 / 10

                return BitcoinFee(
                    minimalSatoshiPerByte: minRate,
                    normalSatoshiPerByte: normalRate,
                    prioritySatoshiPerByte: priorityRate
                )
            }
            .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<String, Error> {
        send(transaction: RavencoinRawTransaction.Request(rawtx: transaction))
            .map { $0.txid }
            .eraseToAnyPublisher()
    }

    func push(transaction: String) -> AnyPublisher<String, Error> {
        .anyFail(error: BlockchainSdkError.networkProvidersNotSupportsRbf)
    }

    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        .anyFail(error: BlockchainSdkError.notImplemented)
    }
}

// MARK: - Mapping

/// Incoming 0.88
/// Outgoing 0.77

private extension RavencoinNetworkProvider {
    func mapToBitcoinResponse(
        wallet: RavencoinWalletInfo,
        outputs: [RavencoinWalletUTXO],
        transactions: [RavencoinTransactionInfo]
    ) -> BitcoinResponse {
        let unspentOutputs = outputs.map { utxo in
            BitcoinUnspentOutput(
                transactionHash: utxo.txid,
                outputIndex: utxo.vout,
                amount: utxo.satoshis,
                outputScript: utxo.scriptPubKey
            )
        }

        let pendingTxRefs = transactions
            .filter { $0.confirmations == 0 || $0.blockheight == -1 }
            .compactMap { transaction -> PendingTransaction? in
                mapToPendingTransaction(transaction: transaction, walletAddress: wallet.address)
            }

        return BitcoinResponse(
            balance: wallet.balance ?? 0,
            hasUnconfirmed: wallet.unconfirmedTxApperances != 0,
            pendingTxRefs: pendingTxRefs,
            unspentOutputs: unspentOutputs
        )
    }

    func mapToPendingTransaction(
        transaction: RavencoinTransactionInfo,
        walletAddress: String
    ) -> PendingTransaction? {
        let isIncoming = transaction.vin.allSatisfy { $0.addr != walletAddress }
        let hash = transaction.txid
        let timestamp = transaction.time * 1000
        let fee = transaction.fees
        let value: Decimal

        if isIncoming {
            // Find all outputs to the our address
            let outputs = transaction.vout.filter {
                $0.scriptPubKey.addresses.contains { $0 == walletAddress }
            }

            value = outputs.compactMap { Decimal($0.value) }.reduce(0, +)

        } else {
            // Find all outputs from the our address
            let outputs = transaction.vout.filter {
                $0.scriptPubKey.addresses.contains { $0 != walletAddress }
            }

            value = outputs.compactMap { Decimal($0.value) }.reduce(0, +)
        }

        let otherAddresses = transaction.vout.filter {
            $0.scriptPubKey.addresses.contains { $0 != walletAddress }
        }

        guard let otherAddress = otherAddresses.first?.scriptPubKey.addresses.first else {
            return nil
        }

        return PendingTransaction(
            hash: hash,
            destination: isIncoming ? walletAddress : otherAddress,
            value: value,
            source: isIncoming ? otherAddress : walletAddress,
            fee: fee,
            date: Date(timeIntervalSince1970: TimeInterval(timestamp)),
            isIncoming: isIncoming,
            transactionParams: nil
        )
    }
}

// MARK: - Private

private extension RavencoinNetworkProvider {
    func getWalletInfo(address: String) -> AnyPublisher<RavencoinWalletInfo, Error> {
        provider
            .requestPublisher(.init(host: host, target: .wallet(address: address)))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RavencoinWalletInfo.self)
            .eraseError()
    }

    func getTransactions(request: RavencoinTransactionHistory.Request) -> AnyPublisher<[RavencoinTransactionInfo], Error> {
        provider
            .requestPublisher(.init(host: host, target: .transactions(request: request)))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RavencoinTransactionHistory.Response.self)
            .map { $0.txs }
            .eraseToAnyPublisher()
            .eraseError()
    }

    func getUTXO(address: String) -> AnyPublisher<[RavencoinWalletUTXO], Error> {
        provider
            .requestPublisher(.init(host: host, target: .utxo(address: address)))
            .filterSuccessfulStatusAndRedirectCodes()
            .map([RavencoinWalletUTXO].self)
            .eraseError()
    }

    func getFeeRatePerByte(blocks: Int) -> AnyPublisher<Decimal, Error> {
        provider
            .requestPublisher(.init(host: host, target: .fees(request: .init(nbBlocks: blocks))))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapJSON(failsOnEmptyData: true)
            .tryMap { json throws -> Decimal in
                guard let json = json as? [String: Any],
                      let rate = json["\(blocks)"] as? Double else {
                    throw BlockchainSdkError.failedToLoadFee
                }

                let ratePerKilobyte = Decimal(floatLiteral: rate)
                return ratePerKilobyte / 1024
            }
            .eraseToAnyPublisher()
    }

    func getTxInfo(transactionId: String) -> AnyPublisher<RavencoinTransactionInfo, Error> {
        provider
            .requestPublisher(.init(host: host, target: .transaction(id: transactionId)))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RavencoinTransactionInfo.self)
            .eraseError()
    }

    func send(transaction: RavencoinRawTransaction.Request) -> AnyPublisher<RavencoinRawTransaction.Response, Error> {
        provider
            .requestPublisher(.init(host: host, target: .send(transaction: transaction)))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RavencoinRawTransaction.Response.self)
            .eraseToAnyPublisher()
            .eraseError()
    }
}
