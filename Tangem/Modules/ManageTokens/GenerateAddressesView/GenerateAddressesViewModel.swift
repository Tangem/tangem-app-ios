//
//  GenerateAddressesViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 19.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct GenerateAddressesViewModel {
    let numberOfNetworks: Int
    let currentWalletNumber: Int
    let totalWalletNumber: Int
    let didTapGenerate: () -> Void
}
