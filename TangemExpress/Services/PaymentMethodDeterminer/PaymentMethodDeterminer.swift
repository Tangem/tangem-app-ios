//
//  PaymentMethodDeterminer.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 02.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import PassKit

struct PaymentMethodDeterminer {
    private let dataRepository: OnrampDataRepository

    public init(dataRepository: OnrampDataRepository) {
        self.dataRepository = dataRepository
    }
}

extension PaymentMethodDeterminer {
    func preferredPaymentMethod() async throws -> OnrampPaymentMethod {
        let paymentMethods = try await dataRepository.paymentMethods()

        if PKPaymentAuthorizationController.canMakePayments(),
           let applePay = paymentMethods.first(where: { OnrampPaymentMethodType(rawValue: $0.id) == .applePay }) {
            return applePay
        }

        if let card = paymentMethods.first(where: { OnrampPaymentMethodType(rawValue: $0.id) == .card }) {
            return card
        }

        if let first = paymentMethods.first {
            return first
        }

        throw PaymentMethodDeterminerError.paymentMethodNotFound
    }
}

extension PaymentMethodDeterminer {
    enum OnrampPaymentMethodType: String {
        case card
        case applePay = "apple-pay"
    }
}

enum PaymentMethodDeterminerError: LocalizedError {
    case paymentMethodNotFound

    var errorDescription: String? {
        switch self {
        case .paymentMethodNotFound: "The preferred payment method could not be determined"
        }
    }
}
