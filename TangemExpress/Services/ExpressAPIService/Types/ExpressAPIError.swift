//
//  ExpressAPIError.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 05.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressAPIError: Decodable, LocalizedError, Error, Hashable {
    let code: Int?
    let description: String?
    public let value: Value?

    public var errorCode: Code {
        if let code, let codeCase = Code(rawValue: code) {
            return codeCase
        }

        return .unknown
    }

    public var errorDescription: String? {
        code?.description ?? description
    }
}

public extension ExpressAPIError {
    struct Value: Decodable, Hashable {
        let currentAllowance: String?
        let minAmount: String?
        let maxAmount: String?
        let decimals: Int?
        let fromAmount: String?
        let fromAmountProvider: String?

        public var roundUpAmount: Decimal? {
            guard let fromAmountProvider, let decimals else {
                return nil
            }

            return Decimal(string: fromAmountProvider).map { $0 / pow(10, decimals) }
        }

        var amount: Decimal? {
            guard let amount = minAmount ?? maxAmount, let decimals else {
                return nil
            }

            return Decimal(string: amount).map { $0 / pow(10, decimals) }
        }
    }

    enum Code: Int, Decodable, LocalizedError {
        case unknown = -1

        // Service
        case serverError = 2000
        case badRequestError = 2010
        case forbiddenError = 2020
        case notFoundError = 2030
        case requestLoggerError = 2040
        case rateLimitError = 2050

        // CoreError
        case coreError = 2100

        // External error
        case externalServiceError = 2110
        case externalServiceRequestError = 2111
        case externalServiceRequestTimeoutError = 2112
        case externalServiceInvalidAdapterResponse = 2113
        case externalServiceRateLimit = 2114
        case externalServiceBadGateWay = 2115
        case eaRequestTimeoutError = 2120
        case eaInvalidAdapterResponse = 2130

        case exchangeInternalError = 2200
        case exchangeProviderNotFoundError = 2210
        case exchangeProviderNotActiveError = 2220
        case exchangeProviderNotAvailableError = 2230
        case exchangeProviderProviderInternalError = 2231
        case exchangeNotPossibleError = 2240
        case exchangeTooSmallAmountError = 2250
        case exchangeTooBigAmountError = 2251
        case exchangeInvalidAddressError = 2260
        case exchangeNotEnoughBalanceError = 2270
        case exchangeNotEnoughAllowanceError = 2280
        case exchangeInvalidDecimalsError = 2290
        case exchangeUnsupportedRateType = 2300
        case exchangeRoundUpError = 2320
        case networkNotFound = 2330

        case exchangeTransactionNotFoundError = 2500

        public var errorDescription: String? {
            rawValue.description
        }
    }
}
