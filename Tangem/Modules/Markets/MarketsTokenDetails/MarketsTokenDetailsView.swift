//
//  MarketsTokenDetailsView.swift
//  Tangem
//
//  Created by Andrew Son on 24/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

struct MarketsTokenDetailsView: View {
    @ObservedObject var viewModel: MarketsTokenDetailsViewModel

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.mainWindowSize) private var mainWindowSize

    @State private var headerHeight: CGFloat = .zero
    @State private var isListContentObscured = false

    private var isDarkColorScheme: Bool { colorScheme == .dark }

    /// `UIColor` is used since `Color(uiColor:)` constructor loses Xcode color asset dark/light appearance setting.
    @available(iOS, deprecated: 18.0, message: "Replace 'UIColor' with 'Color' since 'Color.mix(with:by:in:)' is available")
    private var defaultBackgroundColor: UIColor {
        isDarkColorScheme ? UIColor.backgroundPrimary.forcedDark : UIColor.backgroundSecondary.forcedLight
    }

    /// `UIColor` is used since `Color(uiColor:)` constructor loses Xcode color asset dark/light appearance setting.
    @available(iOS, deprecated: 18.0, message: "Replace 'UIColor' with 'Color' since 'Color.mix(with:by:in:)' is available")
    private var overlayContentHidingBackgroundColor: UIColor {
        isDarkColorScheme ? defaultBackgroundColor.forcedDark : UIColor.backgroundPlain.forcedLight
    }

    private let scrollViewFrameCoordinateSpaceName = UUID()

    var body: some View {
        rootView
            .if(!viewModel.isMarketsSheetStyle) { view in
                view.navigationTitle(viewModel.tokenName)
            }
            .onOverlayContentStateChange { [weak viewModel] state in
                viewModel?.onOverlayContentStateChange(state)
            }
            .onOverlayContentProgressChange { [weak viewModel] progress in
                viewModel?.onOverlayContentProgressChange(progress)
            }
            .background {
                backgroundColor
                    .ignoresSafeArea(edges: .vertical)
            }
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            scrollView

            navigationBar
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var navigationBar: some View {
        MarketsNavigationBar(
            isMarketsSheetStyle: viewModel.isMarketsSheetStyle,
            title: viewModel.tokenName,
            onBackButtonAction: viewModel.onBackButtonTap
        )
        .background(
            MarketsNavigationBarBackgroundView(
                backdropViewColor: backgroundColor,
                overlayContentHidingProgress: viewModel.overlayContentHidingProgress,
                isNavigationBarBackgroundBackdropViewHidden: viewModel.isNavigationBarBackgroundBackdropViewHidden,
                isListContentObscured: isListContentObscured
            )
        )
        .readGeometry(\.size.height, bindTo: $headerHeight)
        .infinityFrame(axis: .vertical, alignment: .top)
    }

    @ViewBuilder
    private var scrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .center, spacing: 16) {
                // Using plain old overlay + dummy `Color.clear` spacer in the scroll view due to the buggy
                // `safeAreaInset(edge:alignment:spacing:content:)` iOS 15+ API which has both layout and touch-handling issues
                Color.clear
                    .frame(height: headerHeight)

                Group {
                    header

                    picker
                        .padding(.vertical, 8)
                        .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, 16.0)

                chart
                    .hidden(viewModel.allDataLoadFailed)
                    .overlay(content: {
                        UnableToLoadDataView(
                            isButtonBusy: viewModel.isLoading,
                            retryButtonAction: viewModel.loadDetailedInfo
                        )
                        .infinityFrame(axis: .horizontal)
                        .hidden(!viewModel.allDataLoadFailed)
                    })

                content
                    .hidden(viewModel.allDataLoadFailed)
                    .padding(.horizontal, Constants.blockHorizontalPadding)
                    .transition(.opacity)
            }
            .padding(.top, Constants.scrollViewContentTopInset)
            .if(viewModel.isMarketsSheetStyle) { view in
                view
                    .readContentOffset(inCoordinateSpace: .named(scrollViewFrameCoordinateSpaceName)) { contentOffset in
                        isListContentObscured = contentOffset.y > Constants.scrollViewContentTopInset
                    }
            }
        }
        .opacity(viewModel.overlayContentHidingProgress)
        .coordinateSpace(name: scrollViewFrameCoordinateSpaceName)
        .bindAlert($viewModel.alert)
        .tokenDescriptionBottomSheet(
            info: $viewModel.descriptionBottomSheetInfo,
            backgroundColor: Colors.Background.action,
            onGeneratedAITapAction: viewModel.onGenerateAITapAction
        )
        .sheet(item: $viewModel.securityScoreDetailsViewModel) { viewModel in
            MarketsTokenDetailsSecurityScoreDetailsView(viewModel: viewModel)
                .adaptivePresentationDetents()
                .background(Colors.Background.tertiary.ignoresSafeArea())
        }
        .animation(.default, value: viewModel.state)
        .animation(.default, value: viewModel.isLoading)
        .animation(.default, value: viewModel.allDataLoadFailed)
    }

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                if let price = viewModel.price {
                    // This `Text` view acts as an invisible container, maintaining constant height
                    // to prevent UI from jumping when the font of the price label is scaled down
                    Text(Constants.priceLabelSizeMeasureText)
                        .opacity(0.0)
                        .infinityFrame(axis: .horizontal)
                        .overlay(alignment: .leadingFirstTextBaseline) {
                            Text(price)
                                .blinkForegroundColor(
                                    publisher: viewModel.$priceChangeAnimation,
                                    positiveColor: Colors.Text.accent,
                                    negativeColor: Colors.Text.warning,
                                    originalColor: Colors.Text.primary1
                                )
                                .minimumScaleFactor(0.5)
                        }
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(viewModel.priceDate)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                    if let priceChangeState = viewModel.priceChangeState {
                        TokenPriceChangeView(state: priceChangeState, showSkeletonWhenLoading: true)
                    }
                }
                .id(UUID())
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
            isDisabled: viewModel.isLoading && !viewModel.allDataLoadFailed,
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
            description
                .frame(maxWidth: .infinity, alignment: .leading)

            portfolioView

            switch viewModel.state {
            case .loading:
                ContentBlockSkeletons()
            case .loaded:
                contentBlocks
            case .failedToLoadDetails:
                UnableToLoadDataView(
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
            let blocksWidth = mainWindowSize.width - Constants.blockHorizontalPadding * 2
            if let insightsViewModel = viewModel.insightsViewModel {
                MarketsTokenDetailsInsightsView(viewModel: insightsViewModel, viewWidth: blocksWidth)
            }

            if let securityScoreViewModel = viewModel.securityScoreViewModel {
                MarketsTokenDetailsSecurityScoreView(viewModel: securityScoreViewModel)
            }

            if let metricsViewModel = viewModel.metricsViewModel {
                MarketsTokenDetailsMetricsView(viewModel: metricsViewModel, viewWidth: blocksWidth)
            }

            if let pricePerformanceViewModel = viewModel.pricePerformanceViewModel {
                MarketsTokenDetailsPricePerformanceView(viewModel: pricePerformanceViewModel)
            }

            if let numberOfExchangesListedOn = viewModel.numberOfExchangesListedOn {
                MarketsTokenDetailsListedOnExchangesView(exchangesCount: numberOfExchangesListedOn) {
                    viewModel.openExchangesList()
                }
            }

            if !viewModel.linksSections.isEmpty {
                MarketsTokenDetailsLinksView(viewWidth: blocksWidth, sections: viewModel.linksSections)
            }
        }
        .padding(.bottom, 46.0)
    }

    @ViewBuilder
    private var description: some View {
        switch viewModel.state {
        case .loading:
            DescriptionBlockSkeletons()
        case .loaded(let model):
            if let shortDescription = model.shortDescription {
                if model.fullDescription == nil {
                    Text(shortDescription)
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                        .multilineTextAlignment(.leading)
                } else {
                    Button(action: viewModel.openFullDescription) {
                        Group {
                            Text("\(shortDescription) ")
                                + readMoreText
                        }
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                        .multilineTextAlignment(.leading)
                    }
                }
            }
        case .failedToLoadDetails, .failedToLoadAllData:
            EmptyView()
        }
    }

    @ViewBuilder
    private var backgroundColor: Color {
        let uiColor = overlayContentHidingBackgroundColor.mix(
            with: defaultBackgroundColor,
            by: viewModel.overlayContentHidingProgress
        )

        Color(uiColor: uiColor)
    }

    private var readMoreText: Text {
        let readMoreText = Localization.commonReadMore.replacingOccurrences(of: " ", with: AppConstants.unbreakableSpace)
        return Text(readMoreText).foregroundColor(Colors.Text.accent)
    }
}

// MARK: - Constants

private extension MarketsTokenDetailsView {
    enum Constants {
        static let chartHeight: CGFloat = 200.0
        static let scrollViewContentTopInset = 14.0
        static let blockHorizontalPadding: CGFloat = 16.0
        static let priceLabelSizeMeasureText = "1234.0"
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
        marketCap: 100_000_000_000,
        isUnderMarketCapLimit: false
    )

    return MarketsTokenDetailsView(viewModel: .init(
        tokenInfo: tokenInfo,
        presentationStyle: .marketsSheet,
        dataProvider: .init(),
        marketsQuotesUpdateHelper: CommonMarketsQuotesUpdateHelper(),
        coordinator: nil
    ))
}
