//
//  OrganizeTokensListItemViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensListItemViewModel: Hashable, Identifiable {
    let id: AnyHashable

    var name: String { tokenIcon.name }
    var imageURL: URL? { tokenIcon.imageURL }
    var blockchainIconName: String? { tokenIcon.blockchainIconName }

    let balance: LoadableTextView.State
    let isNetworkUnreachable: Bool
    let isDraggable: Bool

    private let tokenIcon: TokenIconInfo

    init(
        id: AnyHashable,
        tokenIcon: TokenIconInfo,
        balance: LoadableTextView.State,
        isNetworkUnreachable: Bool,
        isDraggable: Bool
    ) {
        self.id = id
        self.tokenIcon = tokenIcon
        self.balance = balance
        self.isNetworkUnreachable = isNetworkUnreachable
        self.isDraggable = isDraggable
    }
}
