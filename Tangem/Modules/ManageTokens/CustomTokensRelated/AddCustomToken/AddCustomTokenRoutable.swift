//
//  AddCustomTokenRoutable.swift
//  Tangem
//
//  Created by Andrey Chukavin on 22.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

protocol AddCustomTokenRoutable: AnyObject {
    func dismiss()
    func openWalletSelector(with dataSource: WalletSelectorDataSource)
    func closeWalletSelector()
    func openNetworkSelector(selectedBlockchainNetworkId: String?, blockchains: [Blockchain])
    func openDerivationSelector(selectedDerivationOption: AddCustomTokenDerivationOption, defaultDerivationPath: DerivationPath, blockchainDerivationOptions: [AddCustomTokenDerivationOption])
}
