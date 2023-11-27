//
//  ManageTokensCoordinatorDelegate.swift
//  Tangem
//
//  Created by Andrey Fedorov on 17.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ManageTokensCoordinatorDelegate: AnyObject {
    func showGenerateAddressesWarning(
        numberOfNetworks: Int,
        currentWalletNumber: Int,
        totalWalletNumber: Int,
        action: @escaping () -> Void
    )

    func hideGenerateAddressesWarning()
}
