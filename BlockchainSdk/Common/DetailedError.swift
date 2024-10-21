//
//  DetailedError.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 09.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol DetailedError {
    var detailedDescription: String? { get }
}
