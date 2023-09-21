//
//  WelcomeTokenListView.swift
//  Tangem
//
//  Created by skibinalexander on 18.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct WelcomeTokenListView: View {
    @ObservedObject var viewModel: WelcomeTokenListViewModel

    var body: some View {
        list
            .scrollDismissesKeyboardCompat(true)
            .navigationBarTitle(Text(Localization.commonSearchTokens), displayMode: .automatic)
            .searchableCompat(text: $viewModel.enteredSearchText.value)
            .background(Colors.Background.primary.edgesIgnoringSafeArea(.all))
            .onAppear { viewModel.onAppear() }
            .onDisappear { viewModel.onDisappear() }
    }

    private var list: some View {
        ScrollView {
            LazyVStack {
                if #available(iOS 15.0, *) {} else {
                    SearchBar(text: $viewModel.enteredSearchText.value, placeholder: Localization.commonSearch)
                        .padding(.horizontal, 8)
                        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                divider

                ForEach(viewModel.itemViewModels) {
                    WelcomeTokenListSectionView(model: $0)
                        .padding(.horizontal)

                    divider
                }

                if viewModel.hasNextPage {
                    HStack(alignment: .center) {
                        ActivityIndicatorView(color: .gray)
                            .onAppear(perform: viewModel.fetch)
                    }
                }
            }
        }
    }

    private var divider: some View {
        Divider()
            .padding(.leading)
    }

    @ViewBuilder private var titleView: some View {
        Text(Localization.commonSearchTokens)
            .font(Fonts.Bold.title1)
            .minimumScaleFactor(0.8)
    }
}
