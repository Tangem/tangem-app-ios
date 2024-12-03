//
//  TokenSelectorLocalizable.swift
//  TangemApp
//
//  Created by GuitarKitty on 05.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol TokenSelectorLocalizable {
    var availableTokensListTitle: String { get }
    var unavailableTokensListTitle: String { get }
    var emptySearchMessage: String { get }
    var emptyTokensMessage: String? { get }
}
