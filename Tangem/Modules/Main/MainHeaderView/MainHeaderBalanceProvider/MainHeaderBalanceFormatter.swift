//
//  MainHeaderBalanceFormatter.swift
//  Tangem
//
//  Created by Andrew Son on 09/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MainHeaderBalanceFormatter {
    func formatBalance(balance: Decimal?, currencyCode: String) -> AttributedString
}

extension MainHeaderBalanceFormatter {
    /// The `currencyCode` is  `AppSettings.shared.selectedCurrencyCode`
    func formatBalance(balance: Decimal?) -> AttributedString {
        formatBalance(balance: balance, currencyCode: AppSettings.shared.selectedCurrencyCode)
    }
}

struct CommonMainHeaderBalanceFormatter: MainHeaderBalanceFormatter {
    func formatBalance(balance: Decimal?, currencyCode: String) -> AttributedString {
        let balanceFormatter = BalanceFormatter()
        let formattedBalance = balanceFormatter.formatFiatBalance(balance)
        return balanceFormatter.formatAttributedTotalBalance(fiatBalance: formattedBalance, formattingOptions: .defaultOptions)
    }
}

struct VisaMainHeaderBalanceFormatter: MainHeaderBalanceFormatter {
    func formatBalance(balance: Decimal?, currencyCode: String) -> AttributedString {
        let balanceFormatter = BalanceFormatter()
        guard let balance else {
            return balanceFormatter.formatAttributedTotalBalance(fiatBalance: BalanceFormatter.defaultEmptyBalanceString, formattingOptions: .defaultOptions)
        }
        let formattedBalance = balanceFormatter.formatCryptoBalance(balance, currencyCode: currencyCode)
        return balanceFormatter.formatAttributedTotalBalance(fiatBalance: formattedBalance, formattingOptions: .defaultOptions)
    }
}
