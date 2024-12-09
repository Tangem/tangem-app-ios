//
//  MarketsTokenDetailsExchangesListView.swift
//  Tangem
//
//  Created by Andrew Son on 25.09.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenDetailsExchangesListView: View {
    @ObservedObject var viewModel: MarketsTokenDetailsExchangesListViewModel

    @Environment(\.colorScheme) private var colorScheme

    @State private var isListContentObscured = false
    @State private var headerHeight: CGFloat = .zero
    @State private var safeArea: EdgeInsets = .init()

    private var isDarkColorScheme: Bool { colorScheme == .dark }
    private var defaultBackgroundColor: Color { Colors.Background.primary }

    private let scrollViewFrameCoordinateSpaceName = UUID()
    private let scrollViewContentTopInset = 14.0
    private let navigationBarTitle = Localization.marketsTokenDetailsExchangesTitle

    var body: some View {
        rootView
            .if(!viewModel.isMarketsSheetStyle) { view in
                view.navigationTitle(navigationBarTitle)
            }
            .onOverlayContentStateChange { [weak viewModel] state in
                viewModel?.onOverlayContentStateChange(state)
            }
            .onOverlayContentProgressChange { [weak viewModel] progress in
                viewModel?.onOverlayContentProgressChange(progress)
            }
            .background(defaultBackgroundColor.ignoresSafeArea())
            .animation(.default, value: viewModel.exchangesList)
            .ignoresSafeArea(.container, edges: .top) // Without it, the content won't go into the safe area top zone on over-scroll
            .readGeometry(\.safeAreaInsets, bindTo: $safeArea)
            .onAppear(perform: viewModel.loadExchangesList)
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack(alignment: .top) {
            listContent
                .opacity(viewModel.overlayContentHidingProgress)

            VStack(spacing: 0) {
                if viewModel.isMarketsSheetStyle {
                    MarketsNavigationBar(
                        isMarketsSheetStyle: viewModel.isMarketsSheetStyle,
                        title: navigationBarTitle,
                        onBackButtonAction: viewModel.onBackButtonAction
                    )
                } else {
                    // Native navigation bar is used, so we install an invisible spacer to align the header below the navigation bar
                    Color.clear
                        .frame(height: safeArea.top)
                }

                header
                    .opacity(viewModel.overlayContentHidingProgress)
            }
            .background {
                MarketsNavigationBarBackgroundView(
                    backdropViewColor: defaultBackgroundColor,
                    overlayContentHidingProgress: viewModel.overlayContentHidingProgress,
                    isNavigationBarBackgroundBackdropViewHidden: viewModel.isNavigationBarBackgroundBackdropViewHidden,
                    isListContentObscured: isListContentObscured
                )
            }
            .readGeometry(\.size.height, bindTo: $headerHeight)
            .infinityFrame(axis: .vertical, alignment: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack {
            Text(Localization.marketsTokenDetailsExchange)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            Spacer()

            HStack(spacing: 4) {
                Text(Localization.marketsTokenDetailsVolume)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                Colors.Icon.informative
                    .clipShape(Circle())
                    .frame(size: .init(bothDimensions: 2.5))

                Text(Localization.marketsSelectorInterval24hTitle)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var listContent: some View {
        switch viewModel.exchangesList {
        case .loading, .loaded:
            scrollContent
        case .failedToLoad:
            UnableToLoadDataView(
                isButtonBusy: false,
                retryButtonAction: {
                    viewModel.reloadExchangesList()
                }
            )
            .infinityFrame()
            .padding(.horizontal, 16)
            .padding(.top, headerHeight)
        }
    }

    @ViewBuilder
    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                Color.clear
                    .frame(height: headerHeight)

                switch viewModel.exchangesList {
                case .loading:
                    ForEach(0 ... max(viewModel.numberOfExchangesListedOn - 1, 0)) { _ in
                        ExchangeLoaderView()
                    }
                case .loaded(let itemsList):
                    ForEach(itemsList) { item in
                        MarketsTokenDetailsExchangeItemView(info: item)
                    }
                case .failedToLoad:
                    EmptyView()
                }
            }
            .readContentOffset(inCoordinateSpace: .named(scrollViewFrameCoordinateSpaceName)) { contentOffset in
                isListContentObscured = contentOffset.y > scrollViewContentTopInset
            }
        }
        .coordinateSpace(name: scrollViewFrameCoordinateSpaceName)
    }
}

#Preview {
    MarketsTokenDetailsExchangesListView(
        viewModel: .init(
            tokenId: "ethereum",
            numberOfExchangesListedOn: 5,
            presentationStyle: .marketsSheet,
            exchangesListLoader: MarketsTokenDetailsDataProvider(),
            onBackButtonAction: {}
        )
    )
}
