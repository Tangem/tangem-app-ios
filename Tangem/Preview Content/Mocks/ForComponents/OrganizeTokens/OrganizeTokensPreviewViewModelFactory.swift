//
//  OrganizeTokensPreviewViewModelFactory.swift
//  Tangem
//
//  Created by Andrey Fedorov on 07.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensPreviewViewModelFactory {
    func makeViewModel() -> OrganizeTokensViewModel {
        let coordinator = OrganizeTokensRoutableStub()
        let userWalletModel = UserWalletModelMock()
        let optionsManager = OrganizeTokensOptionsManagerStub()
        let walletModelsAdapter = OrganizeWalletModelsAdapter(
            userTokenListManager: userWalletModel.userTokenListManager,
            organizeTokensOptionsProviding: optionsManager,
            organizeTokensOptionsEditing: optionsManager
        )

        return OrganizeTokensViewModel(
            coordinator: coordinator,
            walletModelsManager: userWalletModel.walletModelsManager,
            walletModelsAdapter: walletModelsAdapter,
            organizeTokensOptionsProviding: optionsManager,
            organizeTokensOptionsEditing: optionsManager
        )
    }
}
