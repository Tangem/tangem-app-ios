//
//  OrganizeTokensListItemViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensListItemViewModel: Hashable, Identifiable {
    var id = UUID()

    var name: String { tokenIcon.name }
    var imageURL: URL? { tokenIcon.imageURL }
    var blockchainIconName: String? { tokenIcon.blockchainIconName }

    var balance: LoadableTextView.State

    var isNetworkUnreachable: Bool
    var isDraggable: Bool

    private let tokenIcon: TokenIconInfo

    init(
        tokenIcon: TokenIconInfo,
        balance: LoadableTextView.State,
        isNetworkUnreachable: Bool,
        isDraggable: Bool
    ) {
        self.tokenIcon = tokenIcon
        self.balance = balance
        self.isNetworkUnreachable = isNetworkUnreachable
        self.isDraggable = isDraggable
    }
}
