//
//  TangemBaseAPIError.swift
//  Tangem
//
//  Created by Andrey Fedorov on 16.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TangemBaseAPIError: Decodable {
    let error: TangemAPIError
}
