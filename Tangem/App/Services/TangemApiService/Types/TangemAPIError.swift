//
//  TangemAPIError.swift
//  Tangem
//
//  Created by Sergey Balashov on 17.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct TangemAPIError: Decodable, LocalizedError {
    let code: ErrorCode
    let message: String?

    var errorDescription: String? {
        message ?? code.description
    }

    init(code: TangemAPIError.ErrorCode, message: String? = nil) {
        self.code = code
        self.message = message
    }
}

extension TangemAPIError {
    enum ErrorCode: Int, Decodable, Equatable {
        // Internal errors
        case unknown = -1
        case decode = -2

        // Server-side errors

        // Promotion
        case promotionCodeNotFound = 101
        case promotionCodeNotApplied = 102
        case promotionCodeAlreadyUsed = 103
        case promotionWalletAlreadyAwarded = 104
        case promotionCardAlreadyAwarded = 105
        case promotionProgramNotFound = 106
        case promotionProgramEnded = 107

        // Blockchain account creation service
        case networkAccountServiceInternalError = 120
        case networkAccountsPerCardLimitReached = 121

        // Misc
        case badRequest = 400
        case forbidden = 403
        case notFound = 404

        /// The description for local errors, for server errors description will be gotten from api
        var description: String? {
            switch self {
            case .badRequest,
                 .forbidden,
                 .notFound,
                 .promotionCodeNotFound,
                 .promotionCodeNotApplied,
                 .promotionCodeAlreadyUsed,
                 .promotionWalletAlreadyAwarded,
                 .promotionCardAlreadyAwarded,
                 .promotionProgramNotFound,
                 .promotionProgramEnded,
                 .networkAccountServiceInternalError,
                 .networkAccountsPerCardLimitReached:
                return nil
            case .decode:
                return "Decoding error"
            case .unknown:
                return "Unknown error"
            }
        }
    }
}
