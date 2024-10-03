//
//  ExpressKeys.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ExpressKeys: Decodable {
    let apiKey: String
    let signVerifierPublicKey: String
}
