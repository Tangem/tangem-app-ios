//
//  SmartContractMethodPrefixCreator.swift
//  TangemVisa
//
//  Created by Andrew Son on 18/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift

struct SmartContractMethodPrefixCreator {
    func createPrefixForMethod(with name: String) -> String {
        String(name.sha3(.keccak256).prefix(8))
    }
}
