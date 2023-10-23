//
//  WalletSelectorDelegate.swift
//  Tangem
//
//  Created by Andrey Chukavin on 18.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletSelectorDelegate: AnyObject {
    func didSelectWallet(with userWalletId: Data)
}
