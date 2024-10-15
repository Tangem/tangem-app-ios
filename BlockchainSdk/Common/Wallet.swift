//
//  Wallet.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 04.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct Wallet {
    // MARK: - Properties

    public let blockchain: Blockchain
    public private(set) var walletAddresses: [AddressType: Address]

    public private(set) var amounts: [Amount.AmountType: Amount] = [:]
    public private(set) var pendingTransactions: [PendingTransactionRecord] = []
    
    // MARK: - Calculations
    
    public var addresses: [Address] { walletAddresses.map { $0.value }.sorted(by: { $0.type < $1.type }) }
    public var defaultAddress: Address { walletAddresses[.default]! }
    
    /// `publicKey` from default address
    public var publicKey: Wallet.PublicKey { defaultAddress.publicKey }
    
    /// Default address
    public var address: String { defaultAddress.value }

    public var isEmpty: Bool {
        return amounts.filter { $0.key != .reserve && !$0.value.isZero }.isEmpty
    }

    public var hasPendingTx: Bool {
        return !pendingTransactions.isEmpty
    }

    public init(blockchain: Blockchain, addresses: [AddressType: Address]) {
        self.blockchain = blockchain
        self.walletAddresses = addresses
    }
    
    public func hasPendingTx(for amountType: Amount.AmountType) -> Bool {
        return pendingTransactions.contains { $0.amount.type == amountType }
    }
    
    /// Explore URL for a specific address
    /// - Parameter address: If nil, default address will be used
    /// - Returns: URL
    public func getExploreURL(for address: String? = nil, token: Token? = nil) -> URL? {
        let address = address ?? self.address
        let provider = ExternalLinkProviderFactory().makeProvider(for: blockchain)
        return provider.url(address: address, contractAddress: token?.contractAddress)
    }
    
    /// Explore URL for a specific transaction by hash
    public func getExploreURL(for transaction: String) -> URL? {
        let provider = ExternalLinkProviderFactory().makeProvider(for: blockchain)
        return provider.url(transaction: transaction)
    }
    
    /// Will return faucet URL for only testnet blockchain. Should use for top-up wallet
    public func getTestnetFaucetURL() -> URL? {
        let provider = ExternalLinkProviderFactory().makeProvider(for: blockchain)
        return provider.testnetFaucetURL
    }
    
    /// Share string for specific address
    /// - Parameter address: If nil, default address will be used
    /// - Returns: String to share
    public func getShareString(for address: String? = nil) -> String {
        let address = address ?? self.address
        return blockchain.getShareString(from: address)
    }
    
    public mutating func add(coinValue: Decimal) {
        let coinAmount = Amount(with: blockchain, type: .coin, value: coinValue)
        add(amount: coinAmount)
    }
    
    public mutating func add(reserveValue: Decimal) {
        let reserveAmount = Amount(with: blockchain, type: .reserve, value: reserveValue)
        add(amount: reserveAmount)
    }
    
    @discardableResult
    public mutating func add(tokenValue: Decimal, for token: Token) -> Amount {
        let tokenAmount = Amount(with: token, value: tokenValue)
        add(amount: tokenAmount)
        return tokenAmount
    }
    
    public mutating func add(amount: Amount) {
        amounts[amount.type] = amount
    }
    
    // MARK: - Internal
    
    mutating func clearAmounts() {
        amounts = [:]
    }

    mutating func clearAmount(for token: Token) {
        amounts[.token(value: token)] = nil
    }

    mutating func set(address: Address) {
        walletAddresses[address.type] = address
    }
}

// MARK: - Pending Transaction

extension Wallet {
    mutating func addPendingTransaction(_ transaction: PendingTransactionRecord) {
        if pendingTransactions.contains(where: { $0.hash == transaction.hash }) {
            return
        }

        pendingTransactions.append(transaction)
    }
    
    mutating func addDummyPendingTransaction() {
        let mapper = PendingTransactionRecordMapper()
        let record = mapper.makeDummy(blockchain: blockchain)
        
        addPendingTransaction(record)
    }
    
    mutating func removePendingTransaction(where compare: (String) -> Bool) {
        pendingTransactions.removeAll { transaction in
            compare(transaction.hash)
        }
    }
    
    mutating func removePendingTransaction(older date: Date) {
        pendingTransactions.removeAll { transaction in
            transaction.date < date
        }
    }
    
    mutating func clearPendingTransaction() {
        pendingTransactions.removeAll()
    }
}
