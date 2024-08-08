//
//  IconURLBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct IconURLBuilder {
    private let baseURL: URL

    init(baseURL: URL = URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/")!) {
        self.baseURL = baseURL
    }

    func tokenIconURL(id: String, size: TokenURLIconSize = .large) -> URL {
        baseURL
            .appendingPathComponent("coins")
            .appendingPathComponent(size.rawValue)
            .appendingPathComponent("\(id).png")
    }

    func tokenIconURL(optionalId: String?, size: TokenURLIconSize = .large) -> URL? {
        guard let optionalId else {
            return nil
        }

        return tokenIconURL(id: optionalId, size: size)
    }

    func fiatIconURL(currencyCode: String) -> URL {
        baseURL
            .appendingPathComponent("currencies")
            .appendingPathComponent("medium")
            .appendingPathComponent("\(currencyCode.lowercased()).png")
    }
}
