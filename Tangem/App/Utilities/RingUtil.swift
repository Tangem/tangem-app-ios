//
//  RingUtil.swift
//  Tangem
//
//  Created by Alexander Osokin on 04.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct RingUtil {
    func isRing(batchId: String) -> Bool {
        batchId.starts(with: "BA")
    }
}
