//
//  SellActionURLHelper.swift
//  Tangem
//
//  Created by Alexander Osokin on 27.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// `tangem://redirect_sell?transactionId=00000-0000-000&baseCurrencyCode=btc&baseCurrencyAmount=10&depositWalletAddress=xxxxxxx&depositWalletAddressTag=000000"`
/// `https://tangem.com/redirect_sell?transactionId=00000-0000-000&baseCurrencyCode=btc&baseCurrencyAmount=10&depositWalletAddress=xxxxxxx&depositWalletAddressTag=000000"`
struct SellActionURLHelper: IncomingActionURLHelper {
    private let pathValue: String = "_sell"

    func buildURL(scheme: IncomingActionScheme) -> URL {
        let urlComponents = URLComponents(string: buildURL(for: scheme))!
        return urlComponents.url!
    }

    func parse(_ url: URL) -> IncomingAction? {
        guard let urlString = url.absoluteStringWithoutQuery else {
            return nil
        }

        for scheme in IncomingActionScheme.allCases {
            if urlString == buildURL(for: scheme) {
                return .dismissSafari(url)
            }
        }

        return nil
    }

    private func buildURL(for scheme: IncomingActionScheme) -> String {
        return "\(scheme.baseScheme)\(pathValue)"
    }
}

private extension URL {
    var absoluteStringWithoutQuery: String? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            return nil
        }

        components.query = nil
        return components.url?.absoluteString
    }
}
