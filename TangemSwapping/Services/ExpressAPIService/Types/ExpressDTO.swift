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
        let rateType: RateType

        enum RateType: String, Codable {
            case float
            case fixed
        }
    }

    struct APIError: Decodable, Error {
        let code: Int
        let description: String
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
            let fromAmount: Decimal
            let providerId: Int
            let rateType: Provider.RateType
        }

        struct Response: Decodable {
            let toAmount: Decimal
            let minAmount: Decimal
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
            let fromAmount: Decimal
            let providerId: Int
            let rateType: Provider.RateType
            let toAddress: String // address for receiving token
        }

        struct Response: Decodable {
            let toAmount: Decimal
            let txType: ExpressTransactionType
            // inner tangem-express transaction id
            let txId: String
            // account for debiting tokens (same as toAddress)
            // for CEX doesn't matter from wich address send
            let txFrom: String
            // swap smart-contract address
            // CEX address for sending transaction
            let txTo: String
            // transaction data
            let txData: String?
            // amount (same as fromAmount)
            let txValue: Decimal
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
}
