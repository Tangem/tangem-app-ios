//
//  BlockchainSdkExampleViewModel.swift
//  BlockchainSdkExample
//
//  Created by Andrey Chukavin on 08.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk
import TangemSdk

class BlockchainSdkExampleViewModel: ObservableObject {
    @Published var cardWallets: [Card.Wallet] = []
    @Published var destination: String = ""
    @Published var amountToSend: String = ""
    @Published var feeDescriptions: [String] = []
    @Published var transactionResult: String = "--"
    @Published var blockchains: [(String, String)] = []
    @Published var curves: [EllipticCurve] = []
    @Published var blockchainName: String = ""
    @Published var isTestnet: Bool = false
    @Published var curve: EllipticCurve = .ed25519
    @Published var tokenExpanded: Bool = false
    @Published var tokenEnabled = false
    @Published var tokenSymbol = ""
    @Published var tokenContractAddress = ""
    @Published var tokenDecimalPlaces = 0
    @Published var sourceAddresses: [Address] = []
    @Published var balance: String = "--"

    @Published var dummyExpanded: Bool = false
    @Published var dummyPublicKey: String = ""
    @Published var dummyAddress: String = ""

    var isUseDummy: Bool {
        !dummyPublicKey.isEmpty || !dummyAddress.isEmpty
    }

    var tokenSectionName: String {
        if let enteredToken = enteredToken {
            return "Token (\(enteredToken.symbol))"
        } else {
            return "Token"
        }
    }

    var enteredToken: BlockchainSdk.Token? {
        guard tokenEnabled else {
            return nil
        }

        guard !tokenContractAddress.isEmpty else {
            return nil
        }

        return BlockchainSdk.Token(name: tokenSymbol, symbol: tokenSymbol, contractAddress: tokenContractAddress, decimalCount: tokenDecimalPlaces)
    }

    let blockchainsWithCurveSelection: [String]

    private let sdk: TangemSdk
    private lazy var walletManagerFactory = {
        let utils = ConfigUtils()
        let apiList = utils.parseProvidersJson()
        return WalletManagerFactory(
            config: utils.parseKeysJson(),
            dependencies: .init(
                accountCreator: SimpleAccountCreator { [weak self] in self?.card },
                dataStorage: InMemoryBlockchainDataStorage { return nil }
            ),
            apiList: apiList
        )
    }()

    @Published private(set) var card: Card?
    @Published private(set) var walletManager: WalletManager?
    private var blockchain: Blockchain?

    private let destinationKey = "destination"
    private let amountKey = "amount"
    private let blockchainNameKey = "blockchainName"
    private let isTestnetKey = "isTestnet"
    private let isShelleyKey = "isShelley"
    private let curveKey = "curve"
    private let tokenEnabledKey = "tokenEnabled"
    private let tokenSymbolKey = "tokenSymbol"
    private let tokenContractAddressKey = "tokenContractAddress"
    private let tokenDecimalPlacesKey = "tokenDecimalPlaces"
    private let walletsKey = "wallets"

    private var bag: Set<AnyCancellable> = []
    private var walletManagerBag: Set<AnyCancellable> = []
    private var walletManagerUpdateSubscription: AnyCancellable?

    init() {
        var config = Config()
        config.logConfig = .verbose
        // initialize at start to handle all logs
        Log.config = config.logConfig
        config.attestationMode = .offline

        sdk = TangemSdk(config: config)

        blockchains = Self.blockchainList()
        curves = EllipticCurve.allCases.sorted { $0.rawValue < $1.rawValue }
        blockchainsWithCurveSelection = [
            Blockchain.stellar(curve: .ed25519, testnet: false),
            Blockchain.solana(curve: .ed25519, testnet: false),
            Blockchain.polkadot(curve: .ed25519, testnet: false),
            Blockchain.kusama(curve: .ed25519),
            Blockchain.azero(curve: .ed25519, testnet: false),
            Blockchain.ton(curve: .ed25519, testnet: false),
            Blockchain.xrp(curve: .ed25519),
            Blockchain.tezos(curve: .ed25519),
            Blockchain.casper(curve: .secp256k1, testnet: false),
        ].map { $0.codingKey }

        if let walletsData = UserDefaults.standard.data(forKey: walletsKey) {
            do {
                cardWallets = try JSONDecoder().decode([Card.Wallet].self, from: walletsData)
            } catch {
                Log.error(error)
            }
        }

        bind()

        destination = UserDefaults.standard.string(forKey: destinationKey) ?? ""
        amountToSend = UserDefaults.standard.string(forKey: amountKey) ?? ""
        blockchainName = UserDefaults.standard.string(forKey: blockchainNameKey) ?? blockchains.first?.1 ?? ""
        isTestnet = UserDefaults.standard.bool(forKey: isTestnetKey)
        curve = EllipticCurve(rawValue: UserDefaults.standard.string(forKey: curveKey) ?? "") ?? curve
        tokenEnabled = UserDefaults.standard.bool(forKey: tokenEnabledKey)
        tokenSymbol = UserDefaults.standard.string(forKey: tokenSymbolKey) ?? ""
        tokenContractAddress = UserDefaults.standard.string(forKey: tokenContractAddressKey) ?? ""
        tokenDecimalPlaces = UserDefaults.standard.integer(forKey: tokenDecimalPlacesKey)

        if ProcessInfo.processInfo.environment["SCAN_ON_START"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.scanCardAndGetInfo()
            }
        }
    }

    func scanCardAndGetInfo() {
        sdk.scanCard { [weak self] result in
            switch result {
            case .failure(let error):
                Log.error(error)
            case .success(let card):
                self?.card = card
            }
        }
    }

    func updateDummyAction() {
        updateWalletManager()
    }

    func clearDummyAction() {
        dummyPublicKey = ""
        dummyAddress = ""
        updateWalletManager()
    }

    func updateBalance() {
        balance = "--"
        walletManagerUpdateSubscription = walletManager?
            .updatePublisher()
            .sink { [weak self] _ in
                // Some blockchains (like `Hedera`) updates wallet addresses asynchronously,
                // so we have to update the UI too
                self?.sourceAddresses = self?.walletManager?.wallet.addresses ?? []
            }
    }

    func copySourceAddressToClipboard(_ sourceAddress: Address) {
        UIPasteboard.general.string = sourceAddress.value
    }

    func checkFee() {
        feeDescriptions = []

        guard
            let amount = parseAmount(),
            let walletManager = walletManager
        else {
            feeDescriptions = ["Invalid amount"]
            return
        }

        walletManager
            .getFee(amount: amount, destination: destination)
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                switch $0 {
                case .failure(let error):
                    Log.error(error)
                    feeDescriptions = [error.localizedDescription]
                case .finished:
                    break
                }
            } receiveValue: { [weak self] in
                self?.feeDescriptions = $0.map { $0.amount.description }
            }
            .store(in: &bag)
    }

    func sendTransaction() {
        transactionResult = "--"

        guard
            let amount = parseAmount(),
            let walletManager = walletManager
        else {
            transactionResult = "Invalid amount"
            return
        }

        walletManager
            .getFee(amount: amount, destination: destination)
            .flatMap { [weak self] fees -> AnyPublisher<TransactionSendResult, Error> in
                guard let self, let fee = fees.first else {
                    return Fail(error: WalletError.failedToGetFee)
                        .eraseToAnyPublisher()
                }

                do {
                    let transaction = try walletManager.createTransaction(
                        amount: amount,
                        fee: fee,
                        destinationAddress: destination
                    )
                    let signer = CommonSigner(sdk: sdk)
                    return walletManager
                        .send(transaction, signer: signer)
                        .mapError {
                            Log.error("sendTxError = \($0.localizedDescription)")
                            return $0.error
                        }
                        .eraseToAnyPublisher()
                } catch {
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                switch $0 {
                case .failure(let error):
                    Log.error(error)
                    self?.transactionResult = error.localizedDescription
                case .finished:
                    self?.transactionResult = "OK"
                }
            } receiveValue: { _ in
            }
            .store(in: &bag)
    }

    // MARK: - Private Implementation

    private func bind() {
        $destination
            .sink { [destinationKey] in
                UserDefaults.standard.set($0, forKey: destinationKey)
            }
            .store(in: &bag)

        $amountToSend
            .sink { [amountKey] in
                UserDefaults.standard.set($0, forKey: amountKey)
            }
            .store(in: &bag)

        $blockchainName
            .dropFirst()
            .sink { [weak self] in
                guard let self else { return }
                UserDefaults.standard.set($0, forKey: blockchainNameKey)
                updateBlockchain(from: $0, isTestnet: isTestnet, curve: curve)
                updateWalletManager()
            }
            .store(in: &bag)

        $isTestnet
            .dropFirst()
            .sink { [weak self] in
                guard let self else { return }
                UserDefaults.standard.set($0, forKey: isTestnetKey)
                updateBlockchain(from: blockchainName, isTestnet: $0, curve: curve)
                updateWalletManager()
            }
            .store(in: &bag)

        $curve
            .dropFirst()
            .sink { [weak self] in
                guard let self else { return }
                UserDefaults.standard.set($0.rawValue, forKey: curveKey)
                updateBlockchain(from: blockchainName, isTestnet: isTestnet, curve: $0)
                updateWalletManager()
            }
            .store(in: &bag)

        $tokenEnabled
            .dropFirst()
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                UserDefaults.standard.set($0, forKey: tokenEnabledKey)
                updateWalletManager()
            }
            .store(in: &bag)

        $tokenSymbol
            .dropFirst()
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                UserDefaults.standard.set($0, forKey: tokenSymbolKey)
                updateWalletManager()
            }
            .store(in: &bag)

        $tokenContractAddress
            .dropFirst()
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                UserDefaults.standard.set($0, forKey: tokenContractAddressKey)
                updateWalletManager()
            }
            .store(in: &bag)

        $tokenDecimalPlaces
            .dropFirst()
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                UserDefaults.standard.set($0, forKey: tokenDecimalPlacesKey)
                updateWalletManager()
            }
            .store(in: &bag)

        $card
            .sink { [weak self] in
                guard let self, let card = $0 else {
                    return
                }

                do {
                    let encodeCardWalletData = try JSONEncoder().encode(card.wallets)
                    UserDefaults.standard.set(encodeCardWalletData, forKey: walletsKey)
                } catch {
                    Log.error(error)
                }

                cardWallets = card.wallets
                updateBlockchain(from: blockchainName, isTestnet: isTestnet, curve: curve)
                updateWalletManager()
            }
            .store(in: &bag)
    }

    private func updateBlockchain(
        from blockchainName: String,
        isTestnet: Bool,
        curve: EllipticCurve
    ) {
        struct BlockchainInfo: Codable {
            let key: String
            let curve: String
            let testnet: Bool
        }

        do {
            let blockchainInfo = BlockchainInfo(key: blockchainName, curve: curve.rawValue, testnet: isTestnet)
            let encodedInfo = try JSONEncoder().encode(blockchainInfo)
            let newBlockchain = try JSONDecoder().decode(Blockchain.self, from: encodedInfo)

            if let blockchain = blockchain, newBlockchain != blockchain {
                destination = ""
                amountToSend = ""
            }

            blockchain = newBlockchain
        } catch {
            Log.error(error)
        }
    }

    private func updateWalletManager() {
        walletManager = nil
        sourceAddresses = []
        feeDescriptions = []
        transactionResult = "--"
        balance = "--"
        walletManagerBag.removeAll()

        guard
            !cardWallets.isEmpty,
            let blockchain = blockchain,
            let wallet = cardWallets.first(where: { $0.curve == blockchain.curve })
        else {
            return
        }

        do {
            let walletManager: WalletManager

            if isUseDummy {
                walletManager = try createStubWalletManager(blockchain: blockchain, wallet: wallet)
            } else {
                walletManager = try createWalletManager(blockchain: blockchain, wallet: wallet)
            }

            self.walletManager = walletManager
            bindWalletManager(walletManager)
            sourceAddresses = walletManager.wallet.addresses
            if let enteredToken = enteredToken {
                walletManager.addToken(enteredToken)
            }
            updateBalance()
        } catch {
            Log.error(error)
        }
    }

    private func bindWalletManager(_ walletManager: WalletManager) {
        walletManager
            .statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .failed(let error):
                    Log.error(error)
                    self?.balance = error.localizedDescription
                case .initial, .loaded, .loading:
                    var balances: [String] = []
                    if let balance = self?.walletManager?.wallet.amounts[.coin]?.description {
                        balances = [balance]
                    } else {
                        balances = ["--"]
                    }

                    let tokens = self?.walletManager?.cardTokens ?? []
                    for token in tokens {
                        if let tokenAmount = self?.walletManager?.wallet.amounts[.token(value: token)] {
                            balances.append(tokenAmount.description)
                        } else {
                            balances.append("--- \(token.symbol)")
                        }
                    }

                    self?.balance = balances.joined(separator: "\n")
                }
            }
            .store(in: &walletManagerBag)
    }

    private func createWalletManager(blockchain: Blockchain, wallet: Card.Wallet) throws -> WalletManager {
        let publicKey = Wallet.PublicKey(seedKey: wallet.publicKey, derivationType: .none)
        return try walletManagerFactory.makeWalletManager(blockchain: blockchain, publicKey: publicKey)
    }

    private func createStubWalletManager(blockchain: Blockchain, wallet: Card.Wallet) throws -> WalletManager {
        return try walletManagerFactory.makeStubWalletManager(
            blockchain: blockchain,
            dummyPublicKey: dummyPublicKey.isEmpty ? wallet.publicKey : Data(hex: dummyPublicKey),
            dummyAddress: dummyAddress
        )
    }

    private func parseAmount() -> Amount? {
        let numberFormatter = NumberFormatter()
        guard
            let value = numberFormatter.number(from: amountToSend)?.decimalValue,
            let blockchain = blockchain
        else {
            return nil
        }

        if let enteredToken = enteredToken {
            return Amount(with: enteredToken, value: value)
        } else {
            return Amount(with: blockchain, value: value)
        }
    }

    private static func blockchainList() -> [(String, String)] {
        return Blockchain.allMainnetCases.map { ($0.displayName, $0.codingKey) }
    }
}
