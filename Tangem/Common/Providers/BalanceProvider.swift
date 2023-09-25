//
//  BalanceProvider.swift
//  Tangem
//
//  Created by Andrew Son on 08/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol BalanceProvider: AnyObject {
    var balancePublisher: AnyPublisher<LoadingValue<BalanceInfo>, Never> { get }
}

struct BalanceInfo {
    let balance: String
    let fiatBalance: String
}
