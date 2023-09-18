//
//  ManageTokensView.swift
//  Tangem
//
//  Created by skibinalexander on 14.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

struct ManageTokensView: View {
    @ObservedObject var viewModel: ManageTokensViewModel

    var body: some View {
        Text(" ManageTokensView - InProgress")
    }
}

struct ManageTokensView_Previews: PreviewProvider {
    static var previews: some View {
        ManageTokensView(viewModel: ManageTokensViewModel())
    }
}
