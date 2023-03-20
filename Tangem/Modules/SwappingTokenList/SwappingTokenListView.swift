//
//  SwappingTokenListView.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SwappingTokenListView: View {
    @ObservedObject private var viewModel: SwappingTokenListViewModel

    private var separatorInset: CGFloat {
        SwappingTokenItemView.iconSize.width + SwappingTokenItemView.horizontalInteritemSpacing
    }

    init(viewModel: SwappingTokenListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            GroupedScrollView(alignment: .center, spacing: 0) {
                if #unavailable(iOS 15.0) {
                    SearchBar(text: $viewModel.searchText.value, placeholder: Localization.commonSearch)
                }

                section(
                    title: Localization.swappingTokenListYourTokens.uppercased(),
                    items: viewModel.userItems
                )

                section(
                    title: Localization.swappingTokenListOtherTokens.uppercased(),
                    items: viewModel.otherItems
                )

                if viewModel.hasNextPage {
                    ProgressViewCompat(color: Colors.Icon.informative)
                        .onAppear(perform: viewModel.fetch)
                }
            }
            .searchableCompat(text: $viewModel.searchText.value)
            .modifier(ifLet: viewModel.navigationTitleViewModel) { view, viewModel in
                if #available(iOS 14.0, *) {
                    view
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                BlockchainNetworkNavigationTitleView(viewModel: viewModel)
                            }
                        }
                } else {
                    view
                        .navigationBarTitle(Text(Localization.swappingTokenListTitle), displayMode: .inline)
                }
            }
        }
    }

    @ViewBuilder
    func section(title: String, items: [SwappingTokenItemViewModel]) -> some View {
        if !items.isEmpty {
            FixedSpacer(height: 12)

            Text(title)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(items) { item in
                SwappingTokenItemView(viewModel: item)

                if items.last?.id != item.id {
                    Separator(color: Colors.Stroke.primary)
                        .padding(.leading, separatorInset)
                }
            }
        }
    }
}
