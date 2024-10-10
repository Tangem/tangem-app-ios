//
//  ErrorCodeProviding.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 13.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol ErrorCodeProviding {
    var errorCode: Int { get }
}
