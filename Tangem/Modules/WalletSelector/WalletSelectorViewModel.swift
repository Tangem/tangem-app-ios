//
//  WalletSelectorViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 18.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class WalletSelectorViewModel: ObservableObject {
    var itemViewModels: [WalletSelectorItemViewModel] = []

    weak var delegate: WalletSelectorDelegate?

    init(userWallets: [UserWallet], currentUserWalletId: Data) {
        itemViewModels = userWallets.map { userWallet in
            WalletSelectorItemViewModel(
                userWallet: userWallet,
                isSelected: userWallet.userWalletId == currentUserWalletId,
                cardImageProvider: CardImageProvider()
            ) { [weak self] in
                self?.didTapWallet(with: userWallet)
            }
        }
    }

    func didTapWallet(with userWallet: UserWallet) {
        for itemViewModel in itemViewModels {
            itemViewModel.isSelected = userWallet.userWalletId == itemViewModel.userWallet.userWalletId
        }

        delegate?.didSelectWallet(with: userWallet.userWalletId)
    }
}
