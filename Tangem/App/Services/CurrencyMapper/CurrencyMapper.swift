//
//  Currency+.swift
//  Tangem
//
//  Created by Sergey Balashov on 06.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemSwapping

struct CurrencyMapper: CurrencyMapping {
    func mapToCurrency(amountType: Amount.AmountType, in blockchain: Blockchain) -> Currency? {
        switch amountType {
        case .token(let token):
            return mapToCurrency(token: token, blockchain: blockchain)
        default:
            return mapToCurrency(blockchain: blockchain)
        }
    }

    func mapToCurrency(token: Token, blockchain: Blockchain) -> Currency? {
        guard let swappingBlockchain = SwappingBlockchain(networkId: blockchain.networkId) else {
            assertionFailure("SwappingBlockchain don't support")
            return nil
        }

        guard let id = token.id else {
            assertionFailure("Token not have id")
            return nil
        }

        return Currency(
            id: id,
            blockchain: swappingBlockchain,
            name: token.name,
            symbol: token.symbol,
            decimalCount: token.decimalCount,
            currencyType: .token(contractAddress: token.contractAddress)
        )
    }

    func mapToCurrency(blockchain: Blockchain) -> Currency? {
        guard let swappingBlockchain = SwappingBlockchain(networkId: blockchain.networkId) else {
            assertionFailure("SwappingBlockchain don't support")
            return nil
        }

        return Currency(
            id: blockchain.coinId,
            blockchain: swappingBlockchain,
            name: blockchain.displayName,
            symbol: blockchain.currencySymbol,
            decimalCount: blockchain.decimalCount,
            currencyType: .coin
        )
    }

    func mapToCurrency(coinModel: CoinModel) -> Currency? {
        let coinType = coinModel.items.first

        switch coinType {
        case .blockchain(let blockchain):
            return mapToCurrency(blockchain: blockchain)
        case .token(let token, let blockchain):
            return mapToCurrency(token: token, blockchain: blockchain)
        case .none:
            assertionFailure("CoinModel haven't items")
            return nil
        }
    }

    func mapToToken(currency: Currency) -> Token? {
        guard let contractAddress = currency.contractAddress else {
            return nil
        }

        return Token(
            name: currency.name,
            symbol: currency.symbol,
            contractAddress: contractAddress,
            decimalCount: currency.decimalCount,
            id: currency.id
        )
    }
}
