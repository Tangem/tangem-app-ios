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
        typealias Id = String

        let providerId: Id
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
        }

        struct Response: Decodable {
            let contractAddress: String
            let network: String
            let exchangeAvailable: Bool
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
            let id: Provider.Id
            let name: String
            let type: ExpressProviderType
            let imageLarge: String?
            let imageSmall: String?
            let termsOfUse: String?
            let privacyPolicy: String?
        }
    }

    // MARK: - ExchangeQuote

    enum ExchangeQuote {
        struct Request: Encodable {
            let fromContractAddress: String
            let fromNetwork: String
            let toContractAddress: String
            let toNetwork: String
            let toDecimals: Int
            let fromAmount: String
            let fromDecimals: Int
            let providerId: Provider.Id
            let rateType: Provider.RateType
        }

        struct Response: Decodable {
            let fromAmount: String
            let fromDecimals: Int
            let toAmount: String
            let toDecimals: Int
            let allowanceContract: String?
        }
    }

    // MARK: - ExchangeData

    enum ExchangeData {
        struct Request: Encodable {
            let requestId: String
            let fromContractAddress: String
            let fromNetwork: String
            let toContractAddress: String
            let toNetwork: String
            let toDecimals: Int
            let fromAmount: String
            let fromDecimals: Int
            let providerId: Provider.Id
            let rateType: Provider.RateType
            let toAddress: String // address for receiving token
        }

        struct Response: Decodable {
            // inner tangem-express transaction id
            let txId: String
            let fromAmount: String
            let fromDecimals: Int
            let toAmount: String
            let toDecimals: Int
            let txDetailsJson: String
            let signature: String
        }
    }

    // MARK: - ExchangeStatus

    enum ExchangeStatus {
        struct Request: Encodable {
            let txId: String
        }

        struct Response: Decodable {
            let providerId: Provider.Id
            let externalTxId: String
            let externalTxStatus: ExpressTransactionStatus
            let externalTxUrl: String
        }
    }

    // MARK: - Error

    enum APIError {
        struct Response: Decodable {
            let error: ExpressAPIError
        }
    }
}
