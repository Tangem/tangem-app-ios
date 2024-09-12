//
//  MarketsPortfolioContainerView.swift
//  Tangem
//
//  Created by skibinalexander on 11.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsPortfolioContainerView: View {
    @ObservedObject var viewModel: MarketsPortfolioContainerViewModel

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            headerView

            contentView
        }
        .if(viewModel.typeView != .list, transform: { view in
            view
                .padding(.bottom, 12) // Bottom padding use for no list views
        })
        .padding(.top, 12) // Need for top padding without bottom padding
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: .zero)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .center) {
                Text(Localization.marketsCommonMyPortfolio)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()

                Button(action: {
                    viewModel.onAddTapAction()
                }, label: {
                    HStack(spacing: 2) {
                        Assets.plus24.image
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Colors.Icon.primary1)
                            .frame(size: .init(bothDimensions: 14))

                        Text(Localization.marketsAddToken)
                            .style(Fonts.Regular.footnote.bold(), color: Colors.Text.primary1)
                    }
                })
                .padding(.leading, 8)
                .padding(.trailing, 10)
                .padding(.vertical, 4)
                .roundedBackground(with: Colors.Button.secondary, padding: .zero, radius: Constants.buttonCornerRadius)
                .hidden(!viewModel.isShowTopAddButton)
            }
        }
    }

    private var contentView: some View {
        VStack(spacing: .zero) {
            switch viewModel.typeView {
            case .empty:
                emptyView
            case .loading:
                loadingView
            case .list:
                listView
            case .unavailable:
                unavailableView
            case .none:
                // Need for dissmis side effect
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var listView: some View {
        LazyVStack(spacing: .zero) {
            let elementItems = viewModel.tokenItemViewModels

            ForEach(indexed: elementItems.indexed()) { index, itemViewModel in
                MarketsPortfolioTokenItemView(viewModel: itemViewModel)
            }
        }
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.marketsAddToMyPortfolioDescription)
                .lineLimit(2)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            MainButton(title: Localization.marketsAddToPortfolioButton) {
                viewModel.onAddTapAction()
            }
        }
    }

    private var unavailableView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack {
                Text(Localization.marketsAddToMyPortfolioUnavailableDescription)
                    .style(.footnote, color: Colors.Text.tertiary)

                Spacer()
            }
        }
    }

    private var loadingView: some View {
        VStack(alignment: .leading, spacing: 6) {
            skeletonView(width: .infinity, height: 15)

            skeletonView(width: 218, height: 15)
        }
    }

    private func skeletonView(width: CGFloat, height: CGFloat) -> some View {
        SkeletonView()
            .cornerRadiusContinuous(3)
            .frame(maxWidth: width, minHeight: height, maxHeight: height)
    }
}

extension MarketsPortfolioContainerView {
    enum TypeView: Int, Identifiable, Hashable {
        case empty
        case list
        case unavailable
        case loading

        var id: Int {
            rawValue
        }
    }
}

private extension MarketsPortfolioContainerView {
    enum Constants {
        static let buttonCornerRadius: CGFloat = 8.0
    }
}
