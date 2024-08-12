//
//  TokenMarketsDetailsView.swift
//  Tangem
//
//  Created by Andrew Son on 24/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenMarketsDetailsView: View {
    @ObservedObject var viewModel: TokenMarketsDetailsViewModel

    @State private var descriptionBottomSheetHeight: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
                Group {
                    header

                    picker
                }
                .padding(.horizontal, 16.0)

                chart
                    .hidden(viewModel.allDataLoadFailed)
                    .overlay(content: {
                        MarketsUnableToLoadDataView(
                            isButtonBusy: viewModel.isLoading,
                            retryButtonAction: viewModel.reloadAllData
                        )
                        .infinityFrame(axis: .horizontal)
                        .hidden(!viewModel.allDataLoadFailed)
                    })

                content
                    .hidden(viewModel.allDataLoadFailed)
                    .padding(.horizontal, 16.0)
                    .transition(.opacity)
            }
            .padding(.top, 14)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Text(viewModel.tokenName))
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .bindAlert($viewModel.alert)
        .descriptionBottomSheet(
            info: $viewModel.descriptionBottomSheetInfo,
            sheetHeight: $descriptionBottomSheetHeight,
            backgroundColor: Colors.Background.action
        )
        .onChange(of: viewModel.descriptionBottomSheetInfo) { value in
            if value == nil {
                descriptionBottomSheetHeight = 0
            }
        }
        .animation(.default, value: viewModel.state)
        .animation(.default, value: viewModel.isLoading)
        .animation(.default, value: viewModel.allDataLoadFailed)
        .onAppear {
            viewModel.onAppear()
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.price)
                    .blinkForegroundColor(
                        publisher: viewModel.$priceChangeAnimation,
                        positiveColor: Colors.Text.accent,
                        negativeColor: Colors.Text.warning,
                        originalColor: Colors.Text.primary1
                    )
                    .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(viewModel.priceDate)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                    TokenPriceChangeView(state: viewModel.priceChangeState, showSkeletonWhenLoading: true)
                }
            }

            Spacer(minLength: 8)

            IconView(url: viewModel.iconURL, size: .init(bothDimensions: 48), forceKingfisher: true)
        }
    }

    @ViewBuilder
    private var picker: some View {
        MarketsPickerView(
            marketPriceIntervalType: $viewModel.selectedPriceChangeIntervalType,
            options: viewModel.priceChangeIntervalOptions,
            shouldStretchToFill: true,
            style: .init(textVerticalPadding: 4),
            titleFactory: { $0.tokenDetailsNameLocalized }
        )
    }

    @ViewBuilder
    private var chart: some View {
        if let viewModel = viewModel.historyChartViewModel {
            MarketsHistoryChartView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 14) {
            switch viewModel.state {
            case .loading:
                portfolioView

                ContentBlockSkeletons()
            case .loaded(let model):
                description(shortDescription: model.shortDescription, fullDescription: model.fullDescription)

                portfolioView

                contentBlocks
            case .failedToLoadDetails:
                MarketsUnableToLoadDataView(
                    isButtonBusy: viewModel.isLoading,
                    retryButtonAction: viewModel.loadDetailedInfo
                )
                .padding(.vertical, 6)
            case .failedToLoadAllData:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var portfolioView: some View {
        if let portfolioViewModel = viewModel.portfolioViewModel {
            MarketsPortfolioContainerView(viewModel: portfolioViewModel)
        }
    }

    @ViewBuilder
    private var contentBlocks: some View {
        VStack(spacing: 14) {
            if let insightsViewModel = viewModel.insightsViewModel {
                MarketsTokenDetailsInsightsView(viewModel: insightsViewModel)
            }

            if let metricsViewModel = viewModel.metricsViewModel {
                MarketsTokenDetailsMetricsView(viewModel: metricsViewModel)
            }

            if let pricePerformanceViewModel = viewModel.pricePerformanceViewModel {
                MarketsTokenDetailsPricePerformanceView(viewModel: pricePerformanceViewModel)
            }

            TokenMarketsDetailsLinksView(sections: viewModel.linksSections)
        }
        .padding(.bottom, 46.0)
    }

    @ViewBuilder
    private func description(shortDescription: String?, fullDescription: String?) -> some View {
        if let shortDescription {
            if fullDescription == nil {
                Text(shortDescription)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    .multilineTextAlignment(.leading)
            } else {
                Button(action: viewModel.openFullDescription) {
                    Group {
                        Text("\(shortDescription) ")
                            + Text(Localization.commonReadMore)
                            .foregroundColor(Colors.Text.accent)
                    }
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    .multilineTextAlignment(.leading)
                }
            }
        }
    }
}

private extension TokenMarketsDetailsView {
    enum Constants {
        static let chartHeight: CGFloat = 200.0
    }
}

// MARK: - Previews

#Preview {
    let tokenInfo = MarketsTokenModel(
        id: "bitcoin",
        name: "Bitcoin",
        symbol: "BTC",
        currentPrice: nil,
        priceChangePercentage: [:],
        marketRating: 1,
        marketCap: 100_000_000_000
    )

    return TokenMarketsDetailsView(viewModel: .init(tokenInfo: tokenInfo, dataProvider: .init(), coordinator: nil))
}
