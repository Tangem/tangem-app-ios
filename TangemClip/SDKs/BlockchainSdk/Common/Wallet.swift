//
//  Wallet.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 04.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public struct Wallet {
    public let blockchain: Blockchain
    public let addresses: [Address]
    
    public var amounts: [Amount.AmountType:Amount] = [:]
    public var transactions: [Transaction] = []
    public var state: WalletState = .created
    
	public var address: String {
		if let address = addresses.first(where: { $0.type == blockchain.defaultAddressType })?.value {
			return address
		} else {
			return addresses.first!.value
		}
	}
    
    public var isEmpty: Bool {
        return amounts.filter { $0.key != .reserve && !$0.value.isEmpty }.isEmpty
    }

    public var hasPendingTx: Bool {
        return !transactions.filter { $0.status == .unconfirmed }.isEmpty
    }
    
    public func hasPendingTx(for amountType: Amount.AmountType) -> Bool {
        return !transactions.filter { $0.status == .unconfirmed && $0.amount.type == amountType }.isEmpty
    }
    
    internal init(blockchain: Blockchain, addresses: [Address]) {
        self.blockchain = blockchain
        self.addresses = addresses
    }
    
    /// Explore URL for specific address
    /// - Parameter address: If nil, default address will be used
    /// - Returns: URL
    public func getExploreURL(for address: String? = nil, token: Token? = nil) -> URL? {
        let address = address ?? self.address
        return blockchain.getExploreURL(from: address, tokenContractAddress: token?.contractAddress)
    }
    
    /// Share string for specific address
    /// - Parameter address: If nil, default address will be used
    /// - Returns: String to share
    public func getShareString(for address: String? = nil) -> String {
        let address = address ?? self.address
        return blockchain.getShareString(from: address)
    }
    
    mutating func clearAmounts() {
        amounts = [:]
    }
    
    mutating func add(coinValue: Decimal, address: String? = nil) {
        let coinAmount = Amount(with: blockchain,
                                address: address ?? self.address,
                                type: .coin,
                                value: coinValue)
        add(amount: coinAmount)
    }
    
    mutating func add(reserveValue: Decimal, address: String? = nil) {
        let reserveAmount = Amount(with: blockchain,
                                   address: address ?? self.address,
                                   type: .reserve,
                                   value: reserveValue)
        add(amount: reserveAmount)
    }
    
    @discardableResult
    mutating func add(tokenValue: Decimal, for token: Token) -> Amount {
        let tokenAmount = Amount(with: token, value: tokenValue)
        add(amount: tokenAmount)
        return tokenAmount
    }
    
    mutating func add(amount: Amount) {
         amounts[amount.type] = amount
    }
    
    mutating func add(transaction: Transaction) {
        var tx = transaction
        tx.date = Date()
        transactions.append(tx)
    }
    
    mutating func addPendingTransaction() {
        let dummyAmount = Amount(with: blockchain, address: "unknown", type: .coin, value: 0)
        var tx = Transaction(amount: dummyAmount,
                             fee: dummyAmount,
                             sourceAddress: "unknown",
                             destinationAddress: address,
                             changeAddress: "unknown")
        tx.date = Date()
        transactions.append(tx)
    }
    
    mutating func remove(token: Token) {
        amounts[.token(value: token)] = nil
    }
}

extension Wallet {
    public enum WalletState {
        case created
        case loaded
    }
    
    public struct PublicKey: Codable, Hashable {
        private let publicKey: Data
        private let derivedKey: Data?
        
        public var signingPublicKey: Data { publicKey }
        public var blockchainPublicKey: Data { derivedKey ?? publicKey }
        
        public init(publicKey: Data, derivedKey: Data?) {
            self.publicKey = publicKey
            self.derivedKey = derivedKey
        }
    }
}
