//
//  WalletSelectorView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 13.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct WalletSelectorView: View {
    @ObservedObject var viewModel: WalletSelectorViewModel

    var body: some View {
        VStack {
            VStack {
                ForEach(viewModel.itemViewModels) { itemViewModel in
                    WalletSelectorItemView(viewModel: itemViewModel)
                }
            }
            .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: .zero)

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .navigationBarTitle(Text(Localization.manageTokensWalletSelectorTitle), displayMode: .inline)
    }
}

struct WalletSelectorView_Previews: PreviewProvider {
    private class PreviewWalletSelectorDataSource: WalletSelectorDataSource {
        private var _selectedUserWalletModel: CurrentValueSubject<UserWalletModel?, Never> = .init(nil)

        var itemViewModels: [WalletSelectorItemViewModel] = []
        var selectedUserWalletIdPublisher: AnyPublisher<UserWalletId?, Never> {
            _selectedUserWalletModel.map { $0?.userWalletId }.eraseToAnyPublisher()
        }
    }

    static var previews: some View {
        WalletSelectorView(
            viewModel: WalletSelectorViewModel(dataSource: PreviewWalletSelectorDataSource())
        )
    }
}
