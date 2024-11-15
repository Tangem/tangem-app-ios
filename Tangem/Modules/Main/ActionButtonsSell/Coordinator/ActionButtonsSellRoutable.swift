//
//  ActionButtonsSellRoutable.swift
//  TangemApp
//
//  Created by GuitarKitty on 12.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ActionButtonsSellRoutable {
    func openSellCrypto(
        from url: URL,
        action: @escaping (String) -> SendToSellModel?
    )
    func dismiss()
}
