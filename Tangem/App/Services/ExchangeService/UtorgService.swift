//
//  UtorgService.swift
//  Tangem
//
//  Created by Andrew Son on 07/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

fileprivate struct UtorgResponse<SuccessResult: Decodable>: Decodable {
    let success: Bool
    let timestamp: Double
    let data: SuccessResult?
    let error: UtorgError?
}

fileprivate enum UtorgErrorType: String, Decodable {
    case unauthorized = "UNAUTHORIZED"
    case unknownError = "UNKNOWN_ERROR"
    case badRequest = "BAD_REQUEST"
}

fileprivate struct UtorgError: Decodable {
    let type: UtorgErrorType
    let message: String?
}

fileprivate struct UtorgCurrency: Decodable {
    let currency: String
    let symbol: String
    let enabled: Bool
    let type: CurrencyType
    let caption: String?
    let chain: String?
}

fileprivate struct UtorgSuccessURLResponse: Decodable {
    let successUrl: String
}

fileprivate enum CurrencyType: String, Decodable {
    case crypto = "CRYPTO"
    case fiat = "FIAT"
}

fileprivate enum UtorgEndpoint: String {
    case currency
    case successUrl
}

class UtorgService {
    @Injected(\.keysManager) var keysManager: KeysManager
    @Published private var initialized: Bool = false

    private var supportedCurrencies = [UtorgCurrency]()

    private var host: String {
        if AppEnvironment.current.isTestnet {
            return "app-stage.utorg.pro"
        }

        return "app.utorg.pro"
    }

    private func currency(with symbol: String, blockchain: Blockchain) -> UtorgCurrency? {
        return supportedCurrencies.first(where: {
            guard
                let chain = $0.chain,
                let utorgBlockchain = Blockchain(from: chain.lowercased()),
                $0.enabled,
                $0.symbol.lowercased() == symbol.lowercased(),
                utorgBlockchain == blockchain
            else {
                return false
            }

            return true
        })
    }
}

extension UtorgService: ExchangeService {
    var initializationPublisher: Published<Bool>.Publisher { $initialized }

    var successCloseUrl: String { "https://success.tangem.com" }

    var sellRequestUrl: String { "" }

    func canBuy(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        AppLog.shared.debug("[Utorg] Can buy: \(currencySymbol). blockchain: \(blockchain)")
        return currency(with: currencySymbol, blockchain: blockchain) != nil
    }

    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        return false
    }

    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        guard let utorgCurrency = currency(with: currencySymbol, blockchain: blockchain) else {
            return nil
        }

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = host

        urlComponents.queryItems = [
            .init(name: "currency", value: utorgCurrency.currency.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)),
        ]

        let url = urlComponents.url?
            .appendingPathComponent("direct")
            .appendingPathComponent(keysManager.utorgSID.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed) ?? "")
            .appendingPathComponent(walletAddress.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed) ?? "")

        return url
    }

    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        return nil
    }

    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        return nil
    }

    func initialize() {
        if initialized {
            return
        }

        runTask { [weak self] in
            guard let self else { return }
            do {
                try await self.loadCurrencies()
                self.initialized = true
                try await self.setSuccessURL()
            } catch {
                AppLog.shared.debug("[Utorg] Failed to initialize Utorg service. Error: \(error)")
            }
        }
    }

    private func loadCurrencies() async throws {
        let currenciesResponse: UtorgResponse<[UtorgCurrency]> = try await performRequest(for: .currency)

        guard let loadedCurrencies = currenciesResponse.data else {
            AppLog.shared.debug("[Utorg] Failed to load currencies data. Currencies response: \(currenciesResponse)")
            return
        }

        supportedCurrencies = loadedCurrencies.filter { $0.type == .crypto }
        AppLog.shared.debug("[Utorg] Receive currencies. Currencies count: \(supportedCurrencies.count)")
    }

    /// Ensures that Utorg UI setup properly. This neede to display button "Back to Account" when user finishes buying crypto in WebView
    private func setSuccessURL() async throws {
        let data = "{\"url\":\"\(successCloseUrl)\"}".data(using: .utf8)
        let response: UtorgResponse<UtorgSuccessURLResponse> = try await performRequest(for: .successUrl, with: data)

        guard let successURL = response.data else {
            AppLog.shared.debug("[Utorg] Failed to set SuccessURL. Success URL response: \(response)")
            return
        }

        AppLog.shared.debug("[Utorg] Success url response: \(successURL)")
    }

    private func performRequest<T: Decodable>(for endpoint: UtorgEndpoint, with data: Data? = nil) async throws -> UtorgResponse<T> {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = host
        urlComponents.path = "/api/merchant/v1/settings/\(endpoint.rawValue)"

        guard let url = urlComponents.url else {
            throw "Failed to create URL for: \(endpoint)"
        }

        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json;charset=UTF-8",
            "X-AUTH-SID": keysManager.utorgSID,
            "X-AUTH-NONCE": UUID().uuidString,
        ]
        request.httpMethod = "POST"

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil

        AppLog.shared.debug("[Utorg] attempting to send request to endpoint: \(endpoint). Request: \(request)")
        let (responseData, _) = try await URLSession(configuration: config).upload(for: request, from: data ?? Data())

        let decoder = JSONDecoder()
        let successURLResponse = try decoder.decode(UtorgResponse<T>.self, from: responseData)

        return successURLResponse
    }
}
