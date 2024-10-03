//
//  MainHeaderUserWalletStateInfoProvider.swift
//  Tangem
//
//  Created by Andrew Son on 09/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MainHeaderUserWalletStateInfoProvider: AnyObject {
    var isUserWalletLocked: Bool { get }
    var isTokensListEmpty: Bool { get }
}
