//
//  GenerateAddressesViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 19.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct GenerateAddressesViewModel: Identifiable {
    var id: Int { hashValue }

    // MARK: - Properties

    let numberOfNetworks: Int
    let currentWalletNumber: Int
    let totalWalletNumber: Int
    let didTapGenerate: () -> Void

    init(numberOfNetworks: Int, currentWalletNumber: Int, totalWalletNumber: Int, didTapGenerate: @escaping () -> Void) {
        self.numberOfNetworks = numberOfNetworks
        self.currentWalletNumber = currentWalletNumber
        self.totalWalletNumber = totalWalletNumber
        self.didTapGenerate = didTapGenerate
    }
}

extension GenerateAddressesViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(numberOfNetworks)
        hasher.combine(currentWalletNumber)
        hasher.combine(totalWalletNumber)
    }

    static func == (lhs: GenerateAddressesViewModel, rhs: GenerateAddressesViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
