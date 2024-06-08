//
//  AddCustomTokenNetworkSelectorItemViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 19.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class AddCustomTokenNetworkSelectorItemViewModel: ObservableObject {
    let networkId: String
    let iconName: String
    let networkName: String
    let currencySymbol: String
    @Published var isSelected: Bool
    let didTapWallet: () -> Void

    init(networkId: String, iconName: String, networkName: String, currencySymbol: String, isSelected: Bool, didTapWallet: @escaping () -> Void) {
        self.networkId = networkId
        self.iconName = iconName
        self.networkName = networkName
        self.currencySymbol = currencySymbol
        self.isSelected = isSelected
        self.didTapWallet = didTapWallet
    }
}
