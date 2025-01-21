//
//  MercuryoService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 05.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import class UIKit.UITraitCollection
import Combine
import BlockchainSdk
import TangemSdk

private enum QueryKey: String {
    case widget_id
    case type
    case currency
    case address
    case signature
    case lang
    case fix_currency
    case redirect_url
    case theme
    case network
}

private struct MercuryoCurrencyResponse: Decodable {
    let data: MercuryoData
}

private struct MercuryoData: Decodable {
    let crypto: [String]
    let config: MercuryoConfig
}

private struct MercuryoConfig: Decodable {
    let cryptoCurrencies: [MercuryoCryptoCurrency]
}

private struct MercuryoCryptoCurrency: Decodable {
    let currency: String
    let network: String
    let contract: String?
}

class MercuryoService {
    @Injected(\.keysManager) private var keysManager: KeysManager

    @Published private var initializeState: ExchangeServiceState = .initializing

    private var widgetId: String {
        keysManager.mercuryoWidgetId
    }

    private var secret: String {
        keysManager.mercuryoSecret
    }

    private var useDarkTheme: Bool {
        UITraitCollection.isDarkMode
    }

    private var cryptoCurrencies: [MercuryoCryptoCurrency] = []

    private var bag: Set<AnyCancellable> = []

    private let darkThemeName = "1inch"

    deinit {
        AppLog.shared.debug("MercuryoService deinit")
    }
}

extension MercuryoService: ExchangeService {
    var initializationPublisher: Published<ExchangeServiceState>.Publisher { $initializeState }

    var successCloseUrl: String { IncomingActionConstants.externalSuccessURL }

    var sellRequestUrl: String { "" }

    // TODO: we don't need a currencySymbol actually
    func canBuy(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        getCryptoCurrency(amountType: amountType, blockchain: blockchain) != nil
    }

    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        return false
    }

    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        guard let cryptoCurrency = getCryptoCurrency(amountType: amountType, blockchain: blockchain) else {
            return nil
        }
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "exchange.mercuryo.io"
        var queryItems = [URLQueryItem]()
        queryItems.append(.init(key: .widget_id, value: widgetId.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .type, value: "buy"))
        queryItems.append(.init(key: .currency, value: cryptoCurrency.currency.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .network, value: cryptoCurrency.network.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .address, value: walletAddress.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .signature, value: signature(for: walletAddress).addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .fix_currency, value: "true"))
        queryItems.append(.init(key: .redirect_url, value: successCloseUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)))

        if let languageCode = Locale.current.languageCode {
            queryItems.append(.init(key: .lang, value: languageCode))
        }

        if useDarkTheme {
            queryItems.append(.init(key: .theme, value: darkThemeName))
        }

        urlComponents.percentEncodedQueryItems = queryItems

        let url = urlComponents.url
        return url
    }

    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        fatalError("TODO: July 2022 - we've decided to only use Mercuryo to buy crypto")
    }

    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        return nil
    }

    func initialize() {
        if initializeState == .initialized {
            return
        }

        initializeState = .initializing

        let request = URLRequest(url: URL(string: "https://api.mercuryo.io/v1.6/lib/currencies")!)

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        URLSession(configuration: config).dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: MercuryoCurrencyResponse.self, decoder: decoder)
            .withWeakCaptureOf(self)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        self?.initializeState = .failed(.networkError)
                    }
                },
                receiveValue: { service, response in
                    service.cryptoCurrencies = response.data.config.cryptoCurrencies
                    service.initializeState = .initialized
                }
            )
            .store(in: &bag)
    }

    private func signature(for address: String) -> String {
        (address + secret).sha512()
    }

    private func getCryptoCurrency(amountType: Amount.AmountType, blockchain: Blockchain) -> MercuryoCryptoCurrency? {
        let symbol = amountType.token?.symbol ?? blockchain.currencySymbol

        guard let mercuryoNetwork = blockchain.mercuryoNetwork else {
            return nil
        }

        let cryptoCurrency = cryptoCurrencies.first(where: {
            let contract = amountType.token?.contractAddress.lowercased() ?? ""
            let cryptoCurrencyContract = $0.contract?.lowercased() ?? ""

            return $0.currency == symbol.uppercased()
                && $0.network == mercuryoNetwork
                && contract == cryptoCurrencyContract
        })

        return cryptoCurrency
    }
}

private extension URLQueryItem {
    init(key: QueryKey, value: String?) {
        self.init(name: key.rawValue, value: value)
    }
}

private extension Blockchain {
    /// https://api.mercuryo.io/v1.6/lib/currencies
    var mercuryoNetwork: String? {
        switch self {
        case .algorand:
            return "ALGORAND"
        case .arbitrum:
            return "ARBITRUM"
        case .avalanche:
            return "AVALANCHE"
        case .bsc:
            return "BINANCESMARTCHAIN"
        case .bitcoin:
            return "BITCOIN"
        case .bitcoinCash:
            return "BITCOINCASH"
        case .cardano:
            return "CARDANO"
        case .cosmos:
            return "COSMOS"
        case .dash:
            return "DASH"
        case .dogecoin:
            return "DOGECOIN"
        case .ethereum:
            return "ETHEREUM"
        case .fantom:
            return "FANTOM"
        case .kusama:
            return "KUSAMA"
        case .litecoin:
            return "LITECOIN"
        case .near:
            return "NEAR_PROTOCOL"
        case .ton:
            return "NEWTON"
        case .optimism:
            return "OPTIMISM"
        case .polkadot:
            return "POLKADOT"
        case .polygon:
            return "POLYGON"
        case .xrp:
            return "RIPPLE"
        case .solana:
            return "SOLANA"
        case .stellar:
            return "STELLAR"
        case .tezos:
            return "TEZOS"
        case .tron:
            return "TRON"
        case .base:
            return "BASE"
        case .ethereumPoW,
             .disChain,
             .ethereumClassic,
             .rsk,
             .binance,
             .ducatus,
             .azero,
             .gnosis,
             .kava,
             .kaspa,
             .ravencoin,
             .terraV1,
             .terraV2,
             .cronos,
             .telos,
             .octa,
             .chia,
             .decimal,
             .veChain,
             .xdc,
             .shibarium,
             .aptos,
             .hedera,
             .areon,
             .playa3ullGames,
             .pulsechain,
             .aurora,
             .manta,
             .zkSync,
             .moonbeam,
             .polygonZkEVM,
             .moonriver,
             .mantle,
             .flare,
             .taraxa,
             .radiant,
             .bittensor,
             .joystream,
             .koinos,
             .internetComputer,
             .cyber,
             .blast,
             .filecoin,
             .sei,
             .sui,
             .energyWebEVM,
             .energyWebX,
             .core,
             .canxium,
             .casper,
             .chiliz,
             .xodex,
             .clore,
             .fact0rn,
             .odysseyChain,
             .bitrock,
             .alephium:
            // Did you get a compilation error here? If so, check whether the network is supported at https://api.mercuryo.io/v1.6/lib/currencies
            return nil
        }
    }
}
