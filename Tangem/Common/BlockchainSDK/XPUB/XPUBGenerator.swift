//
//  XPUBGenerator.swift
//  Tangem
//
//  Created by Alexander Osokin on 10.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol XPUBGenerator {
    func generateXPUB() async throws -> String
}
