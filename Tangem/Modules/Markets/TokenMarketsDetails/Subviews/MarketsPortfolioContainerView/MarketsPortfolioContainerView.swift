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
            .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: .zero)
    }

    @ViewBuilder
    private var headerView: some View {
        switch viewModel.typeView {
        case .empty, .loading, .unavailable, .unsupported:
            BlockHeaderTitleView(title: Localization.marketsCommonMyPortfolio)
        case .list:
            BlockHeaderTitleButtonView(
                title: Localization.marketsCommonMyPortfolio,
                button: .init(
                    asset: Assets.plus14,
                    title: Localization.marketsAddToken,
                    isDisabled: viewModel.isAddTokenButtonDisabled,
                    isLoading: viewModel.isLoadingNetworks
                )
            ) {
                viewModel.onAddTapAction()
            }
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
        case .unsupported:
            viewWithHeader(unsupportedView)
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
                Text(Localization.marketsAddToMyPortfolioUnavailableForWalletDescription)
                    .style(.footnote, color: Colors.Text.tertiary)

                Spacer()
            }
        }
    }

    private var unsupportedView: some View {
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
        VStack(alignment: .leading, spacing: .zero) {
            headerView

            view
        }
    }
}

extension MarketsPortfolioContainerView {
    enum TypeView: Int, Identifiable, Hashable {
        case empty
        case list
        case unsupported
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
