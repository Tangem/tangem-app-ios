//
//  PromotionNetworkModels.swift
//  Tangem
//
//  Created by Andrey Chukavin on 02.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PromotionValidationResult: Decodable {
    let valid: Bool
}

struct PromotionAwardResult: Decodable {
    let status: Bool
}
