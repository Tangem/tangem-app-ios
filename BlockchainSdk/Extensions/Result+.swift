//
//  Result+.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 08.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension Result {
    var value: Success? {
        switch self {
        case .success(let success):
            return success
        case .failure:
            return nil
        }
    }

    var error: Failure? {
        switch self {
        case .success:
            return nil
        case .failure(let failure):
            return failure
        }
    }
}
