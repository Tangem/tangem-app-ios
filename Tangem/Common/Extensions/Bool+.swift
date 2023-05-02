//
//  Bool+.swift
//  Tangem
//
//  Created by Alexander Osokin on 31.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension Bool {
    static var iOS15: Bool {
        if #available(iOS 15, *) {
            return true
        } else {
            return false
        }
    }
}
