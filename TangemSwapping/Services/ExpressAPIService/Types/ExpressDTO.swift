//
//  ExpressDTO.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum ExpressDTO {
    // MARK: - Common

    struct Currency: Codable {
        let contractAddress: String
        let network: String
    }

    struct Provider: Codable {
        let providerId: Int
        let rateTypes: [RateType]

        enum RateType: String, Codable {
            case float
            case fixed
        }
    }

    // MARK: - Assets

    enum Assets {
        struct Request: Encodable {
            let tokensList: [Currency]
            let onlyActive: Bool = true
        }

        struct Response: Decodable {
            let contractAddress: String
            let network: String
            let token: String
            let name: String
            let symbol: String
            let decimals: Int
            let isActive: Bool?
            let exchangeAvailable: Bool
            // Future
            let onrampAvailable: Bool?
            let offrampAvailable: Bool?
        }
    }

    // MARK: - Pairs

    enum Pairs {
        struct Request: Encodable {
            let from: [Currency]
            let to: [Currency]
        }

        struct Response: Decodable {
            let from: Currency
            let to: Currency
            let providers: [Provider]
        }
    }

    // MARK: - Providers

    enum Providers {
        struct Response: Decodable {
            let id: Int
            let name: String
            let type: ExpressProviderType
            let imageLarge: String
            let imageSmall: String
        }
    }

    // MARK: - ExchangeQuote

    enum ExchangeQuote {
        struct Request: Encodable {
            let fromContractAddress: String
            let fromNetwork: String
            let toContractAddress: String
            let toNetwork: String
            let fromAmount: String
            let fromDecimals: Int
            let providerId: Int
            let rateType: Provider.RateType
        }

        struct Response: Decodable {
            let fromAmount: String
            let fromDecimals: Int
            let toAmount: String
            let toDecimals: Int
            let minAmount: String
            let allowanceContract: String?
        }
    }

    // MARK: - ExchangeData

    enum ExchangeData {
        struct Request: Encodable {
            let fromContractAddress: String
            let fromNetwork: String
            let toContractAddress: String
            let toNetwork: String
            let fromAmount: String
            let fromDecimals: Int
            let providerId: Int
            let rateType: Provider.RateType
            let toAddress: String // address for receiving token
        }

        struct Response: Decodable {
            let fromAmount: String
            let fromDecimals: Int
            let toAmount: String
            let toDecimals: Int

            let txType: ExpressTransactionType
            // inner tangem-express transaction id
            let txId: String
            // account for debiting tokens (same as toAddress)
            // for CEX doesn't matter from wich address send
            let txFrom: String?
            // swap smart-contract address
            // CEX address for sending transaction
            let txTo: String
            // transaction data
            let txData: String?
            // amount (same as fromAmount)
            let txValue: String
            // CEX provider transaction id
            let externalTxId: String?
            // url of CEX porider exchange status page
            let externalTxUrl: String?
        }
    }

    // MARK: - ExchangeResult

    enum ExchangeResult {
        struct Request: Encodable {
            let txId: String
        }

        struct Response: Decodable {
            let status: ExpressTransactionStatus
            let externalStatus: String
            let externalTxUrl: String
            let errorCode: Int
        }
    }

    // MARK: - Error

    enum APIError {
        struct Response: Decodable {
            let error: ExpressAPIError
        }
    }

    struct ExpressAPIError: Decodable, LocalizedError, Error {
        let code: Code?
        let description: String?
        let value: MinAmountValue?

        struct MinAmountValue: Decodable {
            let minAmount: String
            let decimals: Int

            var amount: Decimal? {
                Decimal(string: minAmount).map { $0 / pow(10, decimals) }
            }
        }

        var errorDescription: String? {
            description
        }

        enum Code: Int, Decodable {
            case badRequest = 2010
            case exchangeProviderNotFoundError = 2210
            case exchangeProviderNotActiveError = 2220
            case exchangeProviderNotAvailableError = 2230
            case exchangeNotPossibleError = 2240
            case exchangeTooSmallAmountError = 2250
            case exchangeInvalidAddressError = 2260
            case exchangeNotEnoughBalanceError = 2270
            case exchangeNotEnoughAllowanceError = 2280
        }
    }
}
