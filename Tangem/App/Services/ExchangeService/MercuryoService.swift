//
//  MercuryoService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 05.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
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
    case return_url
    case theme
}

private struct MercuryoCurrencyResponse: Decodable {
    let data: MercuryoData
}

private struct MercuryoData: Decodable {
    let crypto: [String]
    let config: MercuryoConfig
}

private struct MercuryoConfig: Decodable {
    let base: [String: String]
}

class MercuryoService {
    @Injected(\.keysManager) private var keysManager: KeysManager

    @Published private var initialized = false

    private var widgetId: String {
        keysManager.mercuryoWidgetId
    }

    private var secret: String {
        keysManager.mercuryoSecret
    }

    private var availableCryptoCurrencyCodes: [String] = []
    private var networkCodeByCurrencyCode: [String: String] = [:]

    private var bag: Set<AnyCancellable> = []

    private let darkThemeName = "1inch"

    deinit {
        AppLog.shared.debug("MercuryoService deinit")
    }
}

extension MercuryoService: ExchangeService {
    var initializationPublisher: Published<Bool>.Publisher { $initialized }

    var successCloseUrl: String { "https://success.tangem.com" }

    var sellRequestUrl: String { "" }

    func canBuy(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        guard availableCryptoCurrencyCodes.contains(currencySymbol) else {
            return false
        }

        switch blockchain {
        case .binance, .arbitrum, .optimism:
            return false
        default:
            break
        }

        if let mercuryoNetworkCurrencyCode = networkCodeByCurrencyCode[currencySymbol],
           mercuryoNetworkCurrencyCode.caseInsensitiveCompare(blockchain.currencySymbol) == .orderedSame {
            return true
        } else {
            return false
        }
    }

    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        return false
    }

    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String, useDarkTheme: Bool) -> URL? {
        guard
            canBuy(currencySymbol, amountType: amountType, blockchain: blockchain)
        else {
            return nil
        }

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "exchange.mercuryo.io"

        var queryItems = [URLQueryItem]()
        queryItems.append(.init(key: .widget_id, value: widgetId.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .type, value: "buy"))
        queryItems.append(.init(key: .currency, value: currencySymbol.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .address, value: walletAddress.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .signature, value: signature(for: walletAddress).addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .fix_currency, value: "true"))
        queryItems.append(.init(key: .return_url, value: successCloseUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)))

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

    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String, useDarkTheme: Bool) -> URL? {
        fatalError("TODO: July 2022 - we've decided to only use Mercuryo to buy crypto")
    }

    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        return nil
    }

    func initialize() {
        if initialized {
            return
        }

        let request = URLRequest(url: URL(string: "https://api.mercuryo.io/v1.6/lib/currencies")!)

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil

        URLSession(configuration: config).dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: MercuryoCurrencyResponse.self, decoder: JSONDecoder())
            .sink { _ in

            } receiveValue: { [unowned self] response in
                availableCryptoCurrencyCodes = response.data.crypto
                networkCodeByCurrencyCode = response.data.config.base
                initialized = true
            }
            .store(in: &bag)
    }

    private func signature(for address: String) -> String {
        (address + secret).sha512()
    }
}

private extension URLQueryItem {
    init(key: QueryKey, value: String?) {
        self.init(name: key.rawValue, value: value)
    }
}
