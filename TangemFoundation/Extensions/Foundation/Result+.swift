//
//  Result+.swift
//  TangemFoundation
//
//  Created by Sergey Balashov on 22.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public extension Result {
    var value: Success? {
        switch self {
        case .success(let success):
            return success
        case .failure:
            return nil
        }
    }

    var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let failure):
            return failure
        }
    }
}
