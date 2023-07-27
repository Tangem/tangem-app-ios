//
//  SalesDetails.swift
//  Tangem
//
//  Created by Andrey Chukavin on 25.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct SalesDetails: Codable {
    let sales: [Sale]
}

extension SalesDetails {
    struct Sale: Codable {
        let state: State
        let product: Product
        let notification: Notification?
    }
}

extension SalesDetails.Sale {
    enum State: String, Codable {
        case order
        case preOrder
        case soldOut
    }

    struct Product: Codable {
        let code: String
    }

    struct Notification: Codable {
        let description: String
    }
}
