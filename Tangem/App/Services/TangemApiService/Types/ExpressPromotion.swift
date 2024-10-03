//
//  ExpressPromotion.swift
//  Tangem
//
//  Created by Sergey Balashov on 05.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum ExpressPromotion {}

extension ExpressPromotion {
    struct Request: Encodable {
        let programName: String
    }

    struct Response: Decodable {
        let name: String
        let all: Info

        struct Info: Decodable {
            let timeline: Timeline
            let status: Status
            let link: URL?
        }

        enum Status: String, Decodable {
            case active
            case pending
            case finished
        }
    }
}
