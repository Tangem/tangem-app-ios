//
//  TopupService.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import Alamofire
import Combine
import BlockchainSdk

// MARK: - Models

private enum QueryKey: String {
    case apiKey
    case currencyCode
    case walletAddress
    case redirectURL
    case theme
    case baseCurrencyCode
    case refundWalletAddress
    case signature
    case baseCurrencyAmount
    case depositWalletAddress
    case depositWalletAddressTag
}

private struct IpCheckResponse: Decodable {
    let countryCode: String
    let stateCode: String
    let isMoonpayAllowed: Bool
    let isBuyAllowed: Bool
    let isSellAllowed: Bool

    private enum CodingKeys: String, CodingKey {
        case countryCode = "alpha3"
        case isMoonpayAllowed = "isAllowed"
        case stateCode = "state"
        case isBuyAllowed, isSellAllowed
    }
}

private struct MoonpayCurrency: Decodable {
    enum CurrencyType: String, Decodable {
        case crypto
        case fiat
    }

    struct Metadata: Decodable {
        let contractAddress: String?
        let networkCode: String
    }

    let type: CurrencyType
    let code: String
    let supportsLiveMode: Bool?
    let isSuspended: Bool?
    let isSupportedInUS: Bool?
    let isSellSupported: Bool?
    let notAllowedUSStates: [String]?
    let metadata: Metadata?
}

private struct MoonpaySupportedCurrency: Hashable {
    let currencyCode: String
    let networkCode: String
    let contractAddress: String?
}

// MARK: - Service

class MoonPayService {
    @Injected(\.keysManager) var keysManager: KeysManager

    @Published private var initialized = false

    // TODO: pk_test doesn't
    private var keys: MoonPayKeys { keysManager.moonPayKeys }

    private var availableToBuy: Set<MoonpaySupportedCurrency> = []

    private var availableToSell: Set<MoonpaySupportedCurrency> = []

    private var useDarkTheme: Bool {
        UITraitCollection.isDarkMode
    }

    private(set) var canBuyCrypto = true
    private(set) var canSellCrypto = true
    private var bag: Set<AnyCancellable> = []
    private let darkThemeName = "dark"

    deinit {
        AppLog.shared.debug("MoonPay deinit")
    }

    private func makeSignature(for components: URLComponents) -> URLQueryItem {
        let queryData = "?\(components.percentEncodedQuery!)".data(using: .utf8)!
        let secretKey = keys.secretApiKey.data(using: .utf8)!
        let signature = HMAC<SHA256>.authenticationCode(for: queryData, using: SymmetricKey(data: secretKey))

        return .init(key: .signature, value: Data(signature).base64EncodedString().addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed))
    }
}

extension MoonPayService: ExchangeService {
    var initializationPublisher: Published<Bool>.Publisher { $initialized }

    var successCloseUrl: String { "https://success.tangem.com" }

    var sellRequestUrl: String { SellActionURLHelper().buildURL(scheme: .universalLink).absoluteString }

    func canBuy(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        guard canBuyCrypto else {
            return false
        }

        return getCryptoCurrency(amountType: amountType, blockchain: blockchain, fromCurrencies: availableToBuy) != nil
    }

    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        guard canSellCrypto else {
            return false
        }

        return getCryptoCurrency(amountType: amountType, blockchain: blockchain, fromCurrencies: availableToSell) != nil
    }

    private func getCryptoCurrency(
        amountType: Amount.AmountType,
        blockchain: Blockchain,
        fromCurrencies: Set<MoonpaySupportedCurrency>
    ) -> MoonpaySupportedCurrency? {
        guard let moonpayNetwork = blockchain.moonpayNetwork,
              let moonpayMainCurrencyCode = blockchain.moonpayMainCurrencyCode else {
            return nil
        }

        let cryptoCurrency = fromCurrencies.first(where: {
            switch amountType {
            case .coin:
                return $0.networkCode == moonpayNetwork && $0.currencyCode == moonpayMainCurrencyCode
            case .token(let value):
                return $0.networkCode == moonpayNetwork &&
                    $0.contractAddress?.caseInsensitiveCompare(value.contractAddress) == .orderedSame
            case .reserve, .feeResource:
                return false
            }
        })

        return cryptoCurrency
    }

    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        guard let currency = getCryptoCurrency(amountType: amountType, blockchain: blockchain, fromCurrencies: availableToBuy) else {
            return nil
        }

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "buy.moonpay.io"

        var queryItems = [URLQueryItem]()
        queryItems.append(.init(key: .apiKey, value: keys.apiKey.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .currencyCode, value: currency.currencyCode.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .walletAddress, value: walletAddress.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .redirectURL, value: successCloseUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)))
        queryItems.append(.init(key: .baseCurrencyCode, value: "USD".addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))

        if useDarkTheme {
            queryItems.append(.init(key: .theme, value: darkThemeName))
        }

        urlComponents.percentEncodedQueryItems = queryItems
        let signatureItem = makeSignature(for: urlComponents)
        queryItems.append(signatureItem)
        urlComponents.percentEncodedQueryItems = queryItems

        let url = urlComponents.url
        return url
    }

    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        guard let currency = getCryptoCurrency(amountType: amountType, blockchain: blockchain, fromCurrencies: availableToSell) else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "sell.moonpay.com"

        var queryItems = [URLQueryItem]()
        queryItems.append(.init(key: .apiKey, value: keys.apiKey.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .baseCurrencyCode, value: currency.currencyCode.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .refundWalletAddress, value: walletAddress.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .redirectURL, value: sellRequestUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)))

        if useDarkTheme {
            queryItems.append(.init(key: .theme, value: darkThemeName))
        }

        components.percentEncodedQueryItems = queryItems
        let signature = makeSignature(for: components)
        queryItems.append(signature)
        components.percentEncodedQueryItems = queryItems

        let url = components.url
        return url
    }

    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        guard
            data.starts(with: sellRequestUrl),
            let url = URL(string: data),
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let items = components.queryItems,
            let currencyCode = items.first(where: { $0.name == QueryKey.baseCurrencyCode.rawValue })?.value,
            let amountStr = items.first(where: { $0.name == QueryKey.baseCurrencyAmount.rawValue })?.value,
            let amount = Decimal(string: amountStr),
            let targetAddress = items.first(where: { $0.name == QueryKey.depositWalletAddress.rawValue })?.value
        else {
            return nil
        }

        let tag = items.first(where: { $0.name == QueryKey.depositWalletAddressTag.rawValue })?.value

        return .init(currencyCode: currencyCode, amount: amount, targetAddress: targetAddress, tag: tag)
    }

    func initialize() {
        if initialized {
            return
        }

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil

        let session = URLSession(configuration: config)

        Publishers.Zip(
            session.dataTaskPublisher(for: URL(string: "https://api.moonpay.com/v4/ip_address?" + QueryKey.apiKey.rawValue + "=" + keys.apiKey)!),
            session.dataTaskPublisher(for: URL(string: "https://api.moonpay.com/v3/currencies?" + QueryKey.apiKey.rawValue + "=" + keys.apiKey)!)
        )
        .sink(receiveCompletion: { _ in }) { [weak self] ipOutput, currenciesOutput in
            guard let self = self else { return }
            let decoder = JSONDecoder()
            var countryCode = ""
            var stateCode = ""
            do {
                let decodedResponse = try decoder.decode(IpCheckResponse.self, from: ipOutput.data)
                canBuyCrypto = decodedResponse.isBuyAllowed
                canSellCrypto = decodedResponse.isSellAllowed
                countryCode = decodedResponse.countryCode
                stateCode = decodedResponse.stateCode
            } catch {
                AppLog.shared.debug("Failed to check IP address")
                AppLog.shared.error(error)
            }
            do {
                var currenciesToBuy = Set<MoonpaySupportedCurrency>()
                var currenciesToSell = Set<MoonpaySupportedCurrency>()
                let decodedResponse = try decoder.decode([MoonpayCurrency].self, from: currenciesOutput.data)
                decodedResponse.forEach {
                    guard
                        $0.type == .crypto,
                        let isSuspended = $0.isSuspended, !isSuspended,
                        let supportsLiveMode = $0.supportsLiveMode, supportsLiveMode,
                        let metadata = $0.metadata
                    else { return }

                    if countryCode == "USA" {
                        if $0.isSupportedInUS == false {
                            return
                        }

                        if let notAllowedUSStates = $0.notAllowedUSStates, notAllowedUSStates.contains(stateCode) {
                            return
                        }
                    }

                    let moonpayCurrency = MoonpaySupportedCurrency(
                        currencyCode: $0.code,
                        networkCode: metadata.networkCode,
                        contractAddress: metadata.contractAddress
                    )

                    currenciesToBuy.insert(moonpayCurrency)

                    if $0.isSellSupported == true {
                        currenciesToSell.insert(moonpayCurrency)
                    }
                }
                availableToBuy = currenciesToBuy
                availableToSell = currenciesToSell
            } catch {
                AppLog.shared.debug("Failed to load currencies")
                AppLog.shared.error(error)
            }

            initialized = true
        }
        .store(in: &bag)
    }
}

private extension URLQueryItem {
    init(key: QueryKey, value: String?) {
        self.init(name: key.rawValue, value: value)
    }
}

private extension Blockchain {
    /// https://api.moonpay.com/v3/currencies
    var moonpayNetwork: String? {
        switch self {
        case .algorand: return "algorand"
        case .aptos: return "aptos"
        case .arbitrum: return "arbitrum"
        case .avalanche: return "avalanche_c_chain"
        case .azero: return nil
        case .binance: return "bnb_chain"
        case .bitcoin: return "bitcoin"
        case .bitcoinCash: return "bitcoin_cash"
        case .bsc: return "binance_smart_chain"
        case .cardano: return "cardano"
        case .chia: return nil
        case .cosmos: return "cosmos"
        case .cronos: return nil
        case .dash: return nil
        case .decimal: return nil
        case .disChain: return nil
        case .dogecoin: return "dogecoin"
        case .ducatus: return nil
        case .ethereum: return "ethereum"
        case .ethereumClassic: return "ethereum_classic"
        case .ethereumPoW: return nil
        case .fantom: return nil
        case .gnosis: return nil
        case .hedera: return "hedera"
        case .kaspa, .kaspaKRC20: return nil
        case .kava: return nil
        case .kusama: return nil
        case .litecoin: return "litecoin"
        case .near: return "near"
        case .octa: return nil
        case .optimism: return "optimism"
        case .polkadot: return "polkadot"
        case .polygon: return "polygon"
        case .ravencoin: return "ravencoin"
        case .rsk: return nil
        case .shibarium: return nil
        case .solana: return "solana"
        case .stellar: return "stellar"
        case .telos: return nil
        case .terraV1: return nil
        case .terraV2: return nil
        case .tezos: return "tezos"
        case .ton: return "ton"
        case .tron: return "tron"
        case .veChain: return "vechain"
        case .xdc: return nil
        case .xrp: return "ripple"
        case .areon: return nil
        case .playa3ullGames: return nil
        case .pulsechain: return nil
        case .aurora: return nil
        case .manta: return nil
        case .zkSync: return nil
        case .moonbeam: return nil
        case .polygonZkEVM: return nil
        case .moonriver: return nil
        case .mantle: return nil
        case .flare: return nil
        case .taraxa: return nil
        case .radiant: return nil
        case .base: return "base"
        case .joystream: return nil
        case .bittensor: return nil
        case .koinos: return nil
        case .internetComputer: return nil
        case .cyber: return nil
        case .blast: return nil
        case .filecoin: return "filecoin"
        case .sei: return "sei"
        case .sui: return "sui"
        case .energyWebEVM: return nil
        case .energyWebX: return nil
        case .core: return nil
            // Did you get a compilation error here? If so, check whether the network is supported at https://api.moonpay.com/v3/currencies
        }
    }

    /// We can't compare just by contractAddress presence because of MATIC's  contractAddress
    var moonpayMainCurrencyCode: String? {
        switch self {
        case .algorand: return "algo"
        case .aptos: return "apt"
        case .arbitrum: return "eth_arbitrum"
        case .avalanche: return "avax_cchain"
        case .azero: return nil
        case .binance: return "bnb"
        case .bitcoin: return "btc"
        case .bitcoinCash: return "bch"
        case .bsc: return "bnb_bsc"
        case .cardano: return "ada"
        case .chia: return nil
        case .cosmos: return "atom"
        case .cronos: return nil
        case .dash: return nil
        case .decimal: return nil
        case .disChain: return nil
        case .dogecoin: return "doge"
        case .ducatus: return nil
        case .ethereum: return "eth"
        case .ethereumClassic: return "etc"
        case .ethereumPoW: return nil
        case .fantom: return nil
        case .gnosis: return nil
        case .hedera: return "hbar"
        case .kaspa, .kaspaKRC20: return nil
        case .kava: return nil
        case .kusama: return nil
        case .litecoin: return "ltc"
        case .near: return "near"
        case .octa: return nil
        case .optimism: return "eth_optimism"
        case .polkadot: return "dot"
        case .polygon: return "matic_polygon"
        case .ravencoin: return "rvn"
        case .rsk: return nil
        case .shibarium: return nil
        case .solana: return "sol"
        case .stellar: return "xlm"
        case .telos: return nil
        case .terraV1: return nil
        case .terraV2: return nil
        case .tezos: return "xtz"
        case .ton: return "ton"
        case .tron: return "trx"
        case .veChain: return "vet"
        case .xdc: return nil
        case .xrp: return "xrp"
        case .areon: return nil
        case .playa3ullGames: return nil
        case .pulsechain: return nil
        case .aurora: return nil
        case .manta: return nil
        case .zkSync: return nil
        case .moonbeam: return nil
        case .polygonZkEVM: return nil
        case .moonriver: return nil
        case .mantle: return nil
        case .flare: return nil
        case .taraxa: return nil
        case .radiant: return nil
        case .base: return "eth_base"
        case .joystream: return nil
        case .bittensor: return nil
        case .koinos: return nil
        case .internetComputer: return nil
        case .cyber: return nil
        case .blast: return nil
        case .filecoin: return "fil"
        case .sei: return "sei_sei"
        case .sui: return "sui"
        case .energyWebEVM: return nil
        case .energyWebX: return nil
        case .core: return nil
            // Did you get a compilation error here? If so, check whether the network is supported at https://api.moonpay.com/v3/currencies
        }
    }
}
