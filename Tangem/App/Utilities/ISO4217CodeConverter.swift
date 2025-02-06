//
//  ISO4217CodeConverter.swift
//  Tangem
//
//  Created by Andrew Son on 26/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class ISO4217CodeConverter {
    private(set) static var shared: ISO4217CodeConverter = {
        let converter = ISO4217CodeConverter()
        return converter
    }()

    private var currencies: [ISO4217Currency] = []

    private init() {
        guard
            let url = Bundle.main.url(forResource: "iso4217Codes", withExtension: "plist")
        else {
            return
        }

        do {
            let decoder = PropertyListDecoder()
            let data = try Data(contentsOf: url)
            currencies = try decoder.decode([ISO4217Currency].self, from: data)
        } catch {
            AppLogger.error("Failed to decode currencies", error: error)
        }
    }

    func convertToStringCode(numericCode: Int) -> String? {
        guard let targetCurrency = currencies.first(where: { $0.numericCode == numericCode }) else {
            return nil
        }
        return targetCurrency.currencyCode
    }
}

private struct ISO4217Currency: Decodable {
    let currencyCode: String
    let currency: String
    let country: String
    let minorUnit: String
    let digitsCode: String

    var numericCode: Int {
        Int(digitsCode) ?? -1
    }
}
