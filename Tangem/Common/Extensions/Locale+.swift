//
//  Locale+.swift
//  Tangem
//
//  Created by Andrey Chukavin on 20.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension Locale {
    // Copyright https://github.com/mattt
    // https://gist.github.com/mattt/6d022b66f08ea8c1b99ebe7e48b95c4b
    func localizedCurrencySymbol(forCurrencyCode currencyCode: String) -> String? {
        switch currencyCode {
        case AppConstants.rubCurrencyCode:
            return AppConstants.rubSign
        case AppConstants.usdCurrencyCode:
            return AppConstants.usdSign
        default:
            break
        }

        guard let languageCode = languageCode, let regionCode = regionCode else { return nil }

        /*
          Each currency can have a symbol ($, £, ¥),
          but those symbols may be shared with other currencies.
          For example, in Canadian and American locales,
          the $ symbol on its own implicitly represents CAD and USD, respectively.
          Including the language and region here ensures that
          USD is represented as $ in America and US$ in Canada.
         */
        let components: [String: String] = [
            NSLocale.Key.languageCode.rawValue: languageCode,
            NSLocale.Key.countryCode.rawValue: regionCode,
            NSLocale.Key.currencyCode.rawValue: currencyCode,
        ]

        let identifier = Locale.identifier(fromComponents: components)

        return Locale(identifier: identifier).currencySymbol
    }

    /// See https://developer.apple.com/documentation/foundation/nsdateformatter#2528261 for details.
    static let posixEnUS = Locale(identifier: "en_US_POSIX")
}
