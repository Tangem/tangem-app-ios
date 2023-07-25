//
//  CommonSwappingWalletDataProvider.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 09.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSwapping

class CommonSwappingWalletDataProvider {
    private let wallet: Wallet
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let ethereumTransactionProcessor: EthereumTransactionProcessor
    private let currencyMapper: CurrencyMapping

    private var balances: [Amount.AmountType: Decimal] = [:]
    private var walletAddress: String { wallet.address }

    init(
        wallet: Wallet,
        ethereumNetworkProvider: EthereumNetworkProvider,
        ethereumTransactionProcessor: EthereumTransactionProcessor,
        currencyMapper: CurrencyMapping
    ) {
        self.wallet = wallet
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.ethereumTransactionProcessor = ethereumTransactionProcessor
        self.currencyMapper = currencyMapper

        balances = wallet.amounts.reduce(into: [:]) {
            $0[$1.key] = $1.value.value.rounded(scale: $1.value.decimals, roundingMode: .down)
        }
    }
}

// MARK: - SwappingWalletDataProvider

extension CommonSwappingWalletDataProvider: SwappingWalletDataProvider {
    func getWalletAddress(currency: Currency) -> String? {
        guard wallet.blockchain.networkId == currency.blockchain.networkId else {
            assertionFailure("Incorrect WalletModel")
            return nil
        }

        return walletAddress
    }

    func getGasOptions(
        blockchain: SwappingBlockchain,
        value: Decimal,
        data: Data,
        destinationAddress: String
    ) async throws -> [EthereumGasDataModel] {
        try await getGasOptions(
            blockchain: blockchain,
            value: value,
            data: data,
            destination: destinationAddress
        )
    }

    func getBalance(for currency: Currency) -> Decimal? {
        guard let amountType = mapToAmountType(currency: currency) else {
            return nil
        }

        return balances[amountType]
    }

    func getBalance(for currency: Currency) async throws -> Decimal {
        guard let amountType = mapToAmountType(currency: currency) else {
            throw CommonError.noData
        }

        if let balance = balances[amountType] {
            return balance
        }

        var balance = try await getBalanceFromNetwork(amountType: amountType)
        balance.round(scale: currency.decimalCount, roundingMode: .down)

        balances[amountType] = balance

        return balance
    }

    func getBalance(for blockchain: SwappingBlockchain) async throws -> Decimal {
        guard wallet.blockchain.networkId == blockchain.networkId else {
            assertionFailure("Incorrect WalletModel")
            return 0
        }

        if let balance = balances[.coin] {
            return balance
        }

        let balance = try await getBalanceFromNetwork(amountType: .coin)
        balances[.coin] = balance
        return balance
    }
}

// MARK: - Private

private extension CommonSwappingWalletDataProvider {
    func createAmount(from currency: Currency, amount: Decimal) -> Amount {
        if let token = currencyMapper.mapToToken(currency: currency) {
            return Amount(with: token, value: amount)
        }

        return Amount(
            type: .coin,
            currencySymbol: currency.symbol,
            value: amount,
            decimals: currency.decimalCount
        )
    }

    func createAmount(from blockchain: SwappingBlockchain, amount: Decimal) -> Amount {
        Amount(
            type: .coin,
            currencySymbol: blockchain.symbol,
            value: amount,
            decimals: blockchain.decimalCount
        )
    }

    func getBalanceFromNetwork(amountType: Amount.AmountType) async throws -> Decimal {
        switch amountType {
        case .coin:
            let balance = try await ethereumNetworkProvider.getBalance(walletAddress).async()
            balances[amountType] = balance
            return balance

        case .token(let token):
            let loadedBalances = try await ethereumNetworkProvider.getTokensBalance(
                walletAddress, tokens: [token]
            ).async()

            if let balance = loadedBalances[token] {
                balances[amountType] = balance
                return balance
            }

        case .reserve:
            throw CommonError.notImplemented
        @unknown default:
            throw CommonError.notImplemented
        }

        AppLog.shared.debug("WalletModel haven't balance for amountType \(amountType)")
        return 0
    }

    func getGasOptions(
        blockchain: SwappingBlockchain,
        value: Decimal,
        data: Data,
        destination: String
    ) async throws -> [EthereumGasDataModel] {
        let amount = createAmount(from: blockchain, amount: value)

        let fees = try await ethereumTransactionProcessor.getFee(
            destination: destination,
            value: amount.encodedForSend,
            data: data
        ).async()

        if blockchain == .optimism {
            // According to unusual the Optimism's fee calculation
            // we have to use fee's calculation from BlockchainSDK
            return try getGasOptionsForOptimism(fees: fees)
        }

        guard let fee = fees.first,
              let parameters = fee.parameters as? EthereumFeeParameters else {
            assertionFailure("LowFeeModel don't contains EthereumFeeParameters")
            throw CommonError.noData
        }

        return SwappingGasPricePolicy.allCases.map { policy in
            mapToEthereumGasDataModel(blockchain: blockchain, parameters: parameters, policy: policy)
        }
    }

    func getGasOptionsForOptimism(fees: [Fee]) throws -> [EthereumGasDataModel] {
        guard let normalFee = fees.first,
              let priorityFee = fees.last,
              let normalParameters = normalFee.parameters as? EthereumFeeParameters,
              let priorityParameters = priorityFee.parameters as? EthereumFeeParameters else {
            assertionFailure("LowFeeModel don't contains EthereumFeeParameters")
            throw CommonError.noData
        }

        return [
            EthereumGasDataModel(
                blockchain: .optimism,
                gasPrice: Int(normalParameters.gasPrice),
                gasLimit: Int(normalParameters.gasLimit),
                fee: normalFee.amount.value,
                policy: .normal
            ),
            EthereumGasDataModel(
                blockchain: .optimism,
                gasPrice: Int(priorityParameters.gasPrice),
                gasLimit: Int(priorityParameters.gasLimit),
                fee: priorityFee.amount.value,
                policy: .priority
            ),
        ]
    }

    func mapToEthereumGasDataModel(
        blockchain: SwappingBlockchain,
        parameters: EthereumFeeParameters,
        policy: SwappingGasPricePolicy
    ) -> EthereumGasDataModel {
        // Default increasing the gas limit. Just in case
        let gasLimit = Int(parameters.gasLimit) * 112 / 100
        let gasPrice = policy.increased(value: Int(parameters.gasPrice))

        return EthereumGasDataModel(
            blockchain: blockchain,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            fee: blockchain.convertFromWEI(value: Decimal(gasLimit * gasPrice)),
            policy: policy
        )
    }

    func mapToAmountType(currency: Currency) -> Amount.AmountType? {
        switch currency.currencyType {
        case .token:
            guard let token = currencyMapper.mapToToken(currency: currency) else {
                assertionFailure("Currency isn't a token")
                return nil
            }

            return Amount.AmountType.token(value: token)
        case .coin:
            return Amount.AmountType.coin
        }
    }
}
