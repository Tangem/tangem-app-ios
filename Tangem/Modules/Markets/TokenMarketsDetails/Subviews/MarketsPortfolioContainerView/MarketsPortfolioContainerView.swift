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
        .padding(.top, 12) // Need for top padding without bottom padding
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: .zero)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .center) {
                Text(Localization.marketsCommonMyPortfolio)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()

                if viewModel.isShowTopAddButton {
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
                }
            }
        }
    }

    private var contentView: some View {
        VStack(spacing: .zero) {
            switch viewModel.typeView {
            case .empty:
                emptyView
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
}

extension MarketsPortfolioContainerView {
    enum TypeView: Int, Identifiable, Hashable {
        case empty
        case list
        case unavailable

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
