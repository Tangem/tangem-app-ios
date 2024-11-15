//
//  OnrampStorage.swift
//  TangemApp
//
//  Created by Sergey Balashov on 21.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public protocol OnrampStorage {
    func save(preference: OnrampUserPreference)
    func preference() -> OnrampUserPreference?
}

public struct OnrampUserPreference: Codable {
    var country: Country?
    var currency: Currency?

    init(country: Country? = nil, currency: Currency? = nil) {
        self.country = country
        self.currency = currency
    }
}

extension OnrampUserPreference {
    struct Country: Codable {
        let name: String
        let code: String
        let image: URL?
        let currency: Currency
        let onrampAvailable: Bool
    }

    struct Currency: Codable {
        let name: String
        let code: String
        let image: URL?
        let precision: Int
    }
}
