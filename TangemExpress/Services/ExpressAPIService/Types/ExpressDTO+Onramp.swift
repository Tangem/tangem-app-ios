//
//  ExpressDTO+Onramp.swift
//  TangemApp
//
//  Created by Sergey Balashov on 19.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public extension ExpressDTO {
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

        public enum Status {
            struct Request: Encodable {
                let txId: String
            }

            public struct Response: Decodable {
                public let txId: String
                public let providerId: String // Provider's alphanumeric ID
                public let payoutAddress: String // Address to which the coins are sent
                public let status: OnrampTransactionStatus // Status of the transaction
                public let failReason: String? // Optional field for failure reason
                public let externalTxId: String // External transaction ID
                public let externalTxUrl: String? // Optional URL to track the external transaction
                public let payoutHash: String? // Optional payout hash
                public let createdAt: String // ISO date for when the transaction was created

                public let fromCurrencyCode: String // Source currency
                public let fromAmount: String // Amount of the source currency

                // ToAsset information:
                public let toContractAddress: String
                public let toNetwork: String
                public let toDecimals: Int
                public let toAmount: String?
                public let toActualAmount: String?

                public let paymentMethod: String // Payment method used
                public let countryCode: String // Country code

                public init(
                    txId: String,
                    providerId: String,
                    payoutAddress: String,
                    status: OnrampTransactionStatus,
                    failReason: String?,
                    externalTxId: String,
                    externalTxUrl: String?,
                    payoutHash: String?,
                    createdAt: String,
                    fromCurrencyCode: String,
                    fromAmount: String,
                    toContractAddress: String,
                    toNetwork: String,
                    toDecimals: Int,
                    toAmount: String?,
                    toActualAmount: String?,
                    paymentMethod: String,
                    countryCode: String
                ) {
                    self.txId = txId
                    self.providerId = providerId
                    self.payoutAddress = payoutAddress
                    self.status = status
                    self.failReason = failReason
                    self.externalTxId = externalTxId
                    self.externalTxUrl = externalTxUrl
                    self.payoutHash = payoutHash
                    self.createdAt = createdAt
                    self.fromCurrencyCode = fromCurrencyCode
                    self.fromAmount = fromAmount
                    self.toContractAddress = toContractAddress
                    self.toNetwork = toNetwork
                    self.toDecimals = toDecimals
                    self.toAmount = toAmount
                    self.toActualAmount = toActualAmount
                    self.paymentMethod = paymentMethod
                    self.countryCode = countryCode
                }
            }
        }
    }
}
