//
//  OrganizeTokensPreviewViewModelFactory.swift
//  Tangem
//
//  Created by Andrey Fedorov on 07.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensPreviewViewModelFactory {
    func makeViewModel(for configuration: OrganizeTokensPreviewConfiguration) -> OrganizeTokensViewModel {
        let coordinator = OrganizeTokensRoutableStub()
        let userWalletModel = FakeUserWalletModel.walletWithoutDelay
        let optionsManager = FakeOrganizeTokensOptionsManager(
            initialGroupingOption: configuration.groupingOption,
            initialSortingOption: configuration.sortingOption
        )
        let tokenSectionsAdapter = TokenSectionsAdapter(
            userTokenListManager: userWalletModel.userTokenListManager,
            optionsProviding: optionsManager,
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )

        return OrganizeTokensViewModel(
            coordinator: coordinator,
            userWalletModel: userWalletModel,
            tokenSectionsAdapter: tokenSectionsAdapter,
            optionsProviding: optionsManager,
            optionsEditing: optionsManager
        )
    }
}
