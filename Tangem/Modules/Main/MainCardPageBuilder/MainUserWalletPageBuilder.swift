//
//  MainUserWalletPageBuilder.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum MainUserWalletPageBuilder: Identifiable {
    case singleWallet(id: UserWalletId, headerModel: MainHeaderViewModel, bodyModel: SingleWalletMainContentViewModel)
    case multiWallet(id: UserWalletId, headerModel: MainHeaderViewModel, bodyModel: MultiWalletMainContentViewModel)

    var id: UserWalletId {
        switch self {
        case .singleWallet(let id, _, _):
            return id
        case .multiWallet(let id, _, _):
            return id
        }
    }

    @ViewBuilder
    var header: some View {
        switch self {
        case .singleWallet(_, let headerModel, _):
            MainHeaderView(viewModel: headerModel)
        case .multiWallet(_, let headerModel, _):
            MainHeaderView(viewModel: headerModel)
        }
    }

    @ViewBuilder
    var body: some View {
        switch self {
        case .singleWallet(let id, _, let bodyModel):
            SingleWalletMainContentView(viewModel: bodyModel)
                .id(id)
        case .multiWallet(let id, _, let bodyModel):
            MultiWalletMainContentView(viewModel: bodyModel)
                .id(id)
        }
    }
}
