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
import AlertToast

struct ManageTokensView: View {
    @ObservedObject var viewModel: ManageTokensViewModel

    var body: some View {
        ZStack {
            list

            overlay
        }
        .scrollDismissesKeyboardCompat(true)
        .alert(item: $viewModel.alert, content: { $0.alert })
        .navigationBarTitle(Text(Localization.addTokensTitle), displayMode: .automatic)
        .background(Colors.Background.primary.edgesIgnoringSafeArea(.all))
        .onAppear { viewModel.onAppear() }
    }

    private var list: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.tokenViewModels) {
                ManageTokensItemView(viewModel: $0)
            }

//                if viewModel.hasNextPage {
//                    HStack(alignment: .center) {
//                        ActivityIndicatorView(color: .gray)
//                            .onAppear(perform: viewModel.fetch)
//                    }
//                }
        }
    }

    private var divider: some View {
        Divider()
            .padding(.leading)
    }

    @ViewBuilder private var titleView: some View {
        Text(Localization.addTokensTitle)
            .style(Fonts.Bold.title1, color: Colors.Text.primary1)
    }

    @ViewBuilder private var overlay: some View {
        if let generateAddressViewModel = viewModel.generateAddressesViewModel {
            VStack {
                Spacer()

                GenerateAddressesView(viewModel: generateAddressViewModel)
            }
        }
    }
}
