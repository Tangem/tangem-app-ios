//
//  PendingExpressTxKind.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 11.11.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

enum PendingExpressTxKind {
    case exchange
    case transaction

    var title: String {
        switch self {
        case .exchange:
            Localization.expressExchangeStatusTitle
        case .transaction:
            // TODO: Move to localization
            "Transaction status"
        }
    }

    func statusTitle(providerName: String) -> String {
        switch self {
        case .exchange:
            Localization.expressExchangeBy(providerName)
        case .transaction:
            // TODO: Move to localization
            "Transaction status"
        }
    }
}
