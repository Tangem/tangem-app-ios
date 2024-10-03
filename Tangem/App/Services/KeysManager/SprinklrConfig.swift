//
//  SprinklrConfig.swift
//  Tangem
//
//  Created by Andrey Chukavin on 05.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct SprinklrConfig: Decodable {
    let appID: String
    let apiKey: String
    let environment: String
}
