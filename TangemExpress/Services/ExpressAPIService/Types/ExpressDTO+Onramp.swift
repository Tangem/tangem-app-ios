//
//  ExpressDTO+Onramp.swift
//  TangemApp
//
//  Created by Sergey Balashov on 19.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

extension ExpressDTO {
    enum Onramp {
        // MARK: - Common

        struct Provider: Decodable {
            let providerId: String
            let paymentMethods: [String]
        }

        struct FiatCurrency: Decodable {
            let name: String
            let code: String
            let image: String
            let precision: Int
        }

        struct Country: Decodable {
            let name: String
            let code: String
            let image: String
            let alpha3: String?
            let continent: String?
            let defaultCurrency: FiatCurrency
            let onrampAvailable: Bool
        }

        struct PaymentMethod: Decodable {
            let id: String
            let name: String
            let image: URL
        }

        // MARK: - Pairs

        enum Pairs {
            struct Request: Encodable {
                let fromCurrencyCode: String?
                // alpha2
                let countryCode: String
                let to: [Currency]
            }

            struct Response: Decodable {
                let fromCurrencyCode: String?
                let to: Currency
                let providers: [Provider]
            }
        }

        // MARK: - Quote

        enum Quote {
            struct Request: Encodable {
                let fromCurrencyCode: String
                let toContractAddress: String
                let toNetwork: String
                let paymentMethod: String
                let countryCode: String
                let fromAmount: String
                let toDecimals: Int
                let providerId: String
            }

            struct Response: Decodable {
                let fromCurrencyCode: String
                let toContractAddress: String
                let toNetwork: String
                let paymentMethod: String
                let countryCode: String
                let fromAmount: String
                let toAmount: String
                let toDecimals: Int
                let providerId: String
                let minFromAmount: String
                let maxFromAmount: String
                let minToAmount: String
                let maxToAmount: String
            }
        }

        // MARK: - Data

        enum Data {
            struct Request: Encodable {
                let fromCurrencyCode: String
                let toContractAddress: String
                let toNetwork: String
                let paymentMethod: String
                let countryCode: String
                let fromAmount: String
                let toDecimals: Int
                let providerId: String
                let toAddress: String
                let toExtraId: String? // Optional, as indicated by `?`
                let redirectUrl: String
                let language: String? // Optional
                let theme: String? // Optional
                let requestId: String // Required unique ID
            }

            struct Response: Decodable {
                let txId: String
                let dataJson: String // Decodes the nested JSON object
                let signature: String
            }
        }

        // MARK: - Status

        enum Status {
            struct Request: Encodable {
                let txId: String
            }

            struct Response: Decodable {
                let txId: String
                let providerId: String // Provider's alphanumeric ID
                let payoutAddress: String // Address to which the coins are sent
                let status: String? // Status of the transaction (adjust this type as needed)
                let failReason: String? // Optional field for failure reason
                let externalTxId: String // External transaction ID
                let externalTxUrl: String? // Optional URL to track the external transaction
                let payoutHash: String? // Optional payout hash
                let createdAt: String // ISO date for when the transaction was created

                let fromCurrencyCode: String // Source currency
                let fromAmount: String // Amount of the source currency

                // ToAsset information:
                let toContractAddress: String
                let toNetwork: String
                let toDecimals: Int
                let toAmount: String
                let toActualAmount: String

                let paymentMethod: String // Payment method used
                let countryCode: String // Country code
            }
        }
    }
}
