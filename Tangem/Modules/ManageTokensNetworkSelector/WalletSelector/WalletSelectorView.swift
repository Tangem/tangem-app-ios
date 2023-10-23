//
//  WalletSelectorView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 13.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletSelectorView: View {
    @ObservedObject var viewModel: WalletSelectorViewModel

    var body: some View {
        VStack {
            VStack {
                ForEach(viewModel.itemViewModels) { itemViewModel in
                    WalletSelectorItemView(viewModel: itemViewModel)
                }
            }
            .background(Colors.Background.action)
            .cornerRadiusContinuous(14)
            .padding(16)

            Spacer()
        }
        .background(Colors.Background.secondary.ignoresSafeArea())
        .navigationBarTitle(Text(Localization.manageTokensWalletSelectorTitle), displayMode: .inline)
    }
}

struct WalletSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        WalletSelectorView(viewModel: WalletSelectorViewModel(userWallets: FakeUserWalletModel.allFakeWalletModels.map { $0.userWallet }, currentUserWalletId: FakeUserWalletModel.allFakeWalletModels.first?.userWallet.userWalletId ?? Data()))
    }
}
