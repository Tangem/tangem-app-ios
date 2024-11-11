//
//  SendAmount.swift
//  Tangem
//
//  Created by Sergey Balashov on 13.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendAmount: Hashable {
    private(set) var type: SendAmountType

    var main: Decimal? { type.main }
    var fiat: Decimal? { type.fiat }
    var crypto: Decimal? { type.crypto }

    func toggle(type: SendAmountCalculationType) -> SendAmount {
        switch type {
        case .crypto:
            return .init(type: .typical(crypto: crypto, fiat: fiat))
        case .fiat:
            return .init(type: .alternative(fiat: fiat, crypto: crypto))
        }
    }

    func formatAlternative(
        currencySymbol: String,
        balanceFormatter: BalanceFormatter = .init(),
        trimFractions: Bool = true,
        decimalCount: Int
    ) -> String? {
        switch type {
        case .typical(_, let fiat):
            return fiat.map { balanceFormatter.formatFiatBalance($0) }
        case .alternative(_, let crypto):
            guard let crypto else {
                return BalanceFormatter.defaultEmptyBalanceString
            }

            let formatter = SendCryptoValueFormatter(
                decimals: decimalCount,
                currencySymbol: currencySymbol,
                trimFractions: trimFractions
            )

            return formatter.string(from: crypto)
        }
    }
}

extension SendAmount {
    /**
     Has two cases. Designed for exclude `isFiatCalculation: Bool`
     - `typical` when the user edit `crypto` value and can see `fiat`only as secondary view
     - `alternative` when the user edit `fiat` value  and can see `crypto`only as secondary view
     */
    enum SendAmountType: Hashable {
        case typical(crypto: Decimal?, fiat: Decimal?)
        case alternative(fiat: Decimal?, crypto: Decimal?)

        var fiat: Decimal? {
            switch self {
            case .typical(_, let fiat): fiat
            case .alternative(let fiat, _): fiat
            }
        }

        var crypto: Decimal? {
            switch self {
            case .typical(let crypto, _): crypto
            case .alternative(_, let crypto): crypto
            }
        }

        var main: Decimal? {
            switch self {
            case .typical(let crypto, _): crypto
            case .alternative(let fiat, _): fiat
            }
        }
    }
}

extension SendAmount {
    enum Errors: Error {
        case quoteNotFound
    }
}
