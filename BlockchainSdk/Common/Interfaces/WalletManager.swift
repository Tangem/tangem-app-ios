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

@available(iOS 13.0, *)
public protocol WalletManager: WalletProvider, BlockchainDataProvider, TransactionSender, TransactionCreator, TransactionFeeProvider, TransactionValidator {
    var cardTokens: [Token] { get }
    func update()
    func updatePublisher() -> AnyPublisher<WalletManagerState, Never>
    func setNeedsUpdate()
    func removeToken(_ token: Token)
    func addToken(_ token: Token)
    func addTokens(_ tokens: [Token])
}

@available(iOS 13.0, *)
public enum WalletManagerState {
    case initial
    case loading
    case loaded
    case failed(Error)

    public var isInitialState: Bool {
        switch self {
        case .initial:
            return true
        default:
            return false
        }
    }

    public var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }
}

@available(iOS 13.0, *)
public protocol WalletProvider: AnyObject {
    var wallet: Wallet { get set }
    var walletPublisher: AnyPublisher<Wallet, Never> { get }
    var statePublisher: AnyPublisher<WalletManagerState, Never> { get }
}

extension WalletProvider {
    var defaultSourceAddress: String { wallet.address }
    var defaultChangeAddress: String { wallet.address }
}

public protocol BlockchainDataProvider {
    var currentHost: String { get }
    var outputsCount: Int? { get }
}

extension BlockchainDataProvider {
    var outputsCount: Int? { return nil }
}

@available(iOS 13.0, *)
public protocol TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError>
}

public protocol TransactionSigner {
    func sign(hashes: [Data], walletPublicKeys: [Wallet.PublicKey]) -> AnyPublisher<[Data], Error>
    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error>
    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error>
    func sign(hash: Data, walletPublicKeys: [Wallet.PublicKey]) -> AnyPublisher<[Data], Error>
}

extension TransactionSigner {
    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        sign(hashes: [hash], walletPublicKeys: [walletPublicKey])
            .compactMap { $0.first }
            .eraseToAnyPublisher()
    }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        sign(hashes: hashes, walletPublicKeys: [walletPublicKey])
    }

    func sign(hash: Data, walletPublicKeys: [Wallet.PublicKey]) -> AnyPublisher<[Data], Error> {
        sign(hashes: [hash], walletPublicKeys: walletPublicKeys)
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, Error> {
        sign(hashes: [hash], walletPublicKeys: [walletPublicKey])
            .compactMap { $0.first }
            .eraseToAnyPublisher()
    }

    func sign(hashes: [Data], walletPublicKeys: [Wallet.PublicKey]) -> AnyPublisher<[SignatureInfo], Error> {
        sign(hashes: hashes, walletPublicKeys: walletPublicKeys)
            .map { signatures in
                signatures.enumerated().map { index, signature in
                    SignatureInfo(
                        signature: signature,
                        publicKey: walletPublicKeys[index].blockchainKey,
                        hash: hashes[index]
                    )
                }
            }
            .eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
protocol TransactionPusher {
    func isPushAvailable(for transactionHash: String) -> Bool
    func getPushFee(for transactionHash: String) -> AnyPublisher<[Fee], Error>
    func pushTransaction(with transactionHash: String, newTransaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, SendTxError>
}

@available(iOS 13.0, *)
public protocol SignatureCountValidator {
    func validateSignatureCount(signedHashes: Int) -> AnyPublisher<Void, Error>
}

@available(iOS 13.0, *)
public protocol AddressResolver {
    func resolve(_ address: String) async throws -> String
}

/// Responsible for the token association creation (Hedera) and trust line setup (XRP, Stellar, Aptos, Algorand and other).
@available(iOS 13.0, *)
public protocol AssetRequirementsManager {
    typealias Asset = Amount.AmountType

    func requirementsCondition(for asset: Asset) -> AssetRequirementsCondition?
    func fulfillRequirements(for asset: Asset, signer: any TransactionSigner) -> AnyPublisher<Void, Error>
    /// - Note: The default implementation of this method does nothing.
    func discardRequirements(for asset: Asset)
}

extension AssetRequirementsManager {
    func discardRequirements(for asset: Asset) {
        // No-op
    }
}
