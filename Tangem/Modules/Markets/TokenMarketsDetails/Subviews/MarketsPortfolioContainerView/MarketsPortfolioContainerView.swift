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
        contentView
            .if(viewModel.typeView != .list, transform: { view in
                view
                    .padding(.bottom, 12) // Bottom padding use for no list views
            })
            .padding(.top, 12) // Need for top padding without bottom padding
            .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: .zero)
    }

    private var headerView: some View {
        HStack(alignment: .center) {
            Text(Localization.marketsCommonMyPortfolio)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()

            addTokenButton
        }
    }

    @ViewBuilder
    private var addTokenButton: some View {
        switch viewModel.typeView {
        case .empty, .loading, .unavailable:
            EmptyView()
        case .list:
            Button(action: {
                viewModel.onAddTapAction()
            }, label: {
                HStack(spacing: 2) {
                    Assets.plus14.image
                        .foregroundStyle(viewModel.isAddTokenButtonDisabled ? Colors.Icon.inactive : Colors.Icon.primary1)

                    Text(Localization.marketsAddToken)
                        .style(
                            Fonts.Regular.footnote.bold(),
                            color: viewModel.isAddTokenButtonDisabled ? Colors.Icon.inactive : Colors.Text.primary1
                        )
                }
                .padding(.leading, 8)
                .padding(.trailing, 10)
                .padding(.vertical, 4)
            })
            .background(Colors.Button.secondary)
            .cornerRadiusContinuous(Constants.buttonCornerRadius)
            .skeletonable(isShown: viewModel.isLoadingNetworks, size: .init(width: 60, height: 18), radius: 3, paddings: .init(top: 3, leading: 0, bottom: 3, trailing: 0))
            .disabled(viewModel.isAddTokenButtonDisabled)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.typeView {
        case .empty:
            viewWithHeader(emptyView)
                .transition(.opacity.combined(with: .identity))
        case .loading:
            viewWithHeader(loadingView)
        case .list:
            viewWithHeader(listView)
        case .unavailable:
            viewWithHeader(unavailableView)
                .transition(.opacity.combined(with: .identity))
        }
    }

    @ViewBuilder
    private var listView: some View {
        // Right now we need to use here VStack instead of LazyVStack because of not resolved issues
        // with expanding and collapsing animations for quick actions. Will be investigated in IOS-7971
        VStack(spacing: .zero) {
            let elementItems = viewModel.tokenItemViewModels

            ForEach(indexed: elementItems.indexed()) { index, itemViewModel in
                MarketsPortfolioTokenItemView(
                    viewModel: itemViewModel,
                    isExpanded: viewModel.tokenWithExpandedQuickActions === itemViewModel
                )
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

    @ViewBuilder
    private func viewWithHeader(_ view: some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            headerView

            view
        }
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
