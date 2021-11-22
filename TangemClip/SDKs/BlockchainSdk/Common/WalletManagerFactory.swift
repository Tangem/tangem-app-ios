//
//  WalletManagerFactory.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public class WalletManagerFactory {
    private let config: BlockchainSdkConfig
    
    public init(config: BlockchainSdkConfig) {
        self.config = config
    }
    
    public func makeWalletManagers(for wallet: Card.Wallet, cardId: String, blockchains: [Blockchain]) -> [WalletManager] {
        blockchains.compactMap { makeWalletManager(from: cardId, wallet: wallet, blockchain: $0) }
    }
    
    public func makeWalletManagers(from card: Card, blockchainsProvider: (Card.Wallet) -> [Blockchain]) -> [WalletManager] {

        return card.wallets.reduce([]) { (managers: [WalletManager], wallet) in
            var mangs = managers
            mangs.append(contentsOf:
                blockchainsProvider(wallet).compactMap {
                    makeWalletManager(from: card.cardId , wallet: wallet, blockchain: $0)
                }
            )
            return mangs
        }
    }
    
    /// Base wallet manager constructor
    /// - Parameters:
    ///   - card: Tangem card
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    /// - Returns: WalletManager?
    public func makeWalletManager(from cardId: String, wallet: Card.Wallet, blockchain: Blockchain) -> WalletManager? {
        return makeWalletManager(from: blockchain,
                                 publicKey: wallet.publicKey,
                                 chainCode: wallet.chainCode,
                                 cardId: cardId,
                                 cardCurve: wallet.curve ,
                                 pairPublicKey: nil,
                                 tokens: [])
    }
    
    public func makeTwinWalletManager(from cardId: String, wallet: Card.Wallet, blockchain: Blockchain, pairKey: Data) -> WalletManager? {
        return makeWalletManager(from: blockchain,
                                 publicKey: wallet.publicKey,
                                 chainCode: wallet.chainCode,
                                 cardId: cardId,
                                 cardCurve: wallet.curve,
                                 pairPublicKey: pairKey,
                                 tokens: [])
    }
    
    func makeWalletManager(from blockchain: Blockchain,
                           publicKey: Data,
                           chainCode: Data?,
                           cardId: String,
                           cardCurve: EllipticCurve,
                           pairPublicKey: Data? = nil,
                           tokens: [Token] = []) -> WalletManager? {
        guard blockchain.curve == cardCurve else { return nil }
        
        guard let walletPublicKey = try? blockchain.makePublicKey(publicKey, chainCode: chainCode) else { return nil }
        
        let addresses = blockchain.makeAddresses(from: walletPublicKey.blockchainPublicKey, with: pairPublicKey)
        let wallet = Wallet(blockchain: blockchain,
                            addresses: addresses)
        
        switch blockchain {
        case .bitcoin(let testnet):
            return BitcoinWalletManager(wallet: wallet).then {
                var providers = [BitcoinNetworkProvider]()
                providers.append(BlockchairNetworkProvider(endpoint: .bitcoin, apiKey: config.blockchairApiKey))
                providers.append(BlockcypherNetworkProvider(endpoint: BlockcypherEndpoint(coin: .btc, chain: testnet ? .test3: .main),
                                                              tokens: config.blockcypherTokens))
                $0.networkService = BitcoinNetworkService(providers: providers)
            }
            
        case .litecoin:
            return LitecoinWalletManager(wallet: wallet).then {
                var providers = [BitcoinNetworkProvider]()
                providers.append(BlockcypherNetworkProvider(endpoint: BlockcypherEndpoint(coin: .ltc, chain: .main), tokens: config.blockcypherTokens))
                providers.append(BlockchairNetworkProvider(endpoint: .litecoin, apiKey: config.blockchairApiKey))
                $0.networkService = BitcoinNetworkService(providers: providers)
            }
            
        case .dogecoin:
            return DogecoinWalletManager(wallet: wallet).then {
                var providers = [BitcoinNetworkProvider]()
                providers.append(BlockchairNetworkProvider(endpoint: .dogecoin, apiKey: config.blockchairApiKey))

                $0.networkService = DogecoinNetworkService(providers: providers)
            }
            
        case .ducatus:
            return DucatusWalletManager(wallet: wallet).then {
                $0.networkService = DucatusNetworkService()
            }
            
        case .stellar(let testnet):
            return StellarWalletManager(wallet: wallet, cardTokens: tokens).then {
                let url = testnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
                let stellarSdk = StellarSDK(withHorizonUrl: url)
                $0.stellarSdk = stellarSdk
                $0.networkService = StellarNetworkService(stellarSdk: stellarSdk)
            }
            
        case .ethereum(let testnet):
            return EthereumWalletManager(wallet: wallet, cardTokens: tokens).then {
                let ethereumNetwork = testnet ? EthereumNetwork.testnet(projectId: config.infuraProjectId) : EthereumNetwork.mainnet(projectId: config.infuraProjectId)
                let jsonRpcProviders = [
                    EthereumJsonRpcProvider(network: ethereumNetwork),
                    EthereumJsonRpcProvider(network: .tangem)
                ]
                let blockchair = BlockchairNetworkProvider(endpoint: .bitcoin, apiKey: config.blockchairApiKey)
                $0.networkService = EthereumNetworkService(network: ethereumNetwork, providers: jsonRpcProviders, blockchairProvider: blockchair)
            }
            
        case .rsk:
            return EthereumWalletManager(wallet: wallet, cardTokens: tokens).then {
                let blockchair = BlockchairNetworkProvider(endpoint: .bitcoin, apiKey: config.blockchairApiKey)
                $0.networkService = EthereumNetworkService(network: .rsk, providers: [EthereumJsonRpcProvider(network: .rsk)], blockchairProvider: blockchair)
            }
            
        case .bsc(let testnet):
            return EthereumWalletManager(wallet: wallet).then {
                let network: EthereumNetwork = testnet ? .bscTestnet : .bscMainnet
                $0.networkService = EthereumNetworkService(network: network, providers: [EthereumJsonRpcProvider(network: network)], blockchairProvider: nil)
            }
            
        case .polygon(let testnet):
            return EthereumWalletManager(wallet: wallet).then {
                let network: EthereumNetwork = testnet ? .polygonTestnet : .polygon
                $0.networkService = EthereumNetworkService(network: network, providers: [EthereumJsonRpcProvider(network: network)], blockchairProvider: nil)
            }
            
        case .bitcoinCash:
            return BitcoinCashWalletManager(wallet: wallet).then {
                let provider = BlockchairNetworkProvider(endpoint: .bitcoinCash, apiKey: config.blockchairApiKey)
                $0.networkService = BitcoinCashNetworkService(provider: provider)
            }
            
        case .binance(let testnet):
            return BinanceWalletManager(wallet: wallet, cardTokens: tokens).then {
                $0.networkService = BinanceNetworkService(isTestNet: testnet)
            }
            
        case .cardano:
            return CardanoWalletManager(wallet: wallet).then {
                let service = CardanoNetworkService(providers: [
                    AdaliteNetworkProvider(baseUrl: .main),
                    RosettaNetworkProvider(baseUrl: .tangemRosetta)
                ])
                $0.networkService = service
            }
            
        case .xrp:
            return XRPWalletManager(wallet: wallet).then {
                $0.networkService = XRPNetworkService()
            }
        case .tezos:
            return TezosWalletManager(wallet: wallet).then {
                $0.networkService = TezosNetworkService()
            }
        }
    }
}
