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

    @State private var safeArea: EdgeInsets = .init()
    @State private var isListContentObscured = false
    @State private var headerHeight: CGFloat = .zero

    private var isDarkColorScheme: Bool { colorScheme == .dark }
    private var defaultBackgroundColor: Color { isDarkColorScheme ? Colors.Background.primary : Colors.Background.secondary }
    private var overlayContentHidingBackgroundColor: Color { isDarkColorScheme ? defaultBackgroundColor : Colors.Background.plain }

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
            .background { viewBackground }
            .animation(.default, value: viewModel.exchangesList)
            .ignoresSafeArea(.container, edges: .top) // Without it, the content won't go into the safe area top zone on over-scroll
            .readGeometry(\.safeAreaInsets, bindTo: $safeArea)
    }

    @ViewBuilder
    private var rootView: some View {
        let content = ZStack(alignment: .top) {
            listContent
                .opacity(viewModel.overlayContentHidingProgress)

            VStack(spacing: 0) {
                navigationBar

                header
                    .opacity(viewModel.overlayContentHidingProgress)
                    .padding(.top, safeArea.top)
            }
            .background {
                MarketsNavigationBarBackgroundView(
                    backdropViewColor: overlayContentHidingBackgroundColor,
                    overlayContentHidingProgress: viewModel.overlayContentHidingProgress,
                    isNavigationBarBackgroundBackdropViewHidden: viewModel.isNavigationBarBackgroundBackdropViewHidden,
                    isListContentObscured: isListContentObscured
                )
            }
            .readGeometry(\.size.height, bindTo: $headerHeight)
            .infinityFrame(axis: .vertical, alignment: .top)
        }

        if #unavailable(iOS 17.0), viewModel.isMarketsSheetStyle {
            // On iOS 16 and below, UIKit will always allocate a new instance of the `UINavigationBar` instance when push
            // navigation is performed in other navigation controller(s) in the application (on the main screen, for example).
            // This will happen asynchronously, after a couple of seconds after the navigation event in the other navigation controller(s).
            // Therefore, we left with two options:
            // - Perform swizzling in `UINavigationController` and manually hide that new navigation bar.
            // - Hiding navigation bar using native `UINavigationController.setNavigationBarHidden(_:animated:)` from UIKit
            //   and `navigationBarHidden(_:)` from SwiftUI, which in turn will break the swipe-to-pop gesture.
            content
                .navigationBarHidden(true)
        } else {
            content
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var navigationBar: some View {
        if viewModel.isMarketsSheetStyle {
            NavigationBar(
                title: navigationBarTitle,
                settings: .init(
                    title: .init(
                        font: Fonts.Bold.body,
                        color: Colors.Text.primary1,
                        lineLimit: 1,
                        minimumScaleFactor: 0.6
                    ),
                    backgroundColor: .clear, // Controlled by the `background` modifier in the body
                    height: 64.0,
                    alignment: .bottom
                ),
                leftButtons: {
                    BackButton(
                        height: 44.0,
                        isVisible: true,
                        isEnabled: true,
                        hPadding: 10.0,
                        action: viewModel.onBackButtonAction
                    )
                }
            )
        }
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
            MarketsUnableToLoadDataView(
                isButtonBusy: false,
                retryButtonAction: {
                    viewModel.reloadExchangesList()
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, headerHeight)
        }
    }

    @ViewBuilder
    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: headerHeight)

                switch viewModel.exchangesList {
                case .loading:
                    ForEach(0 ... (viewModel.numberOfExchangesListedOn - 1)) { _ in
                        ExchangeLoaderView()
                    }
                case .loaded(let itemsList):
                    ForEach(indexed: itemsList.indexed()) { item in
                        MarketsTokenDetailsExchangeItemView(info: item.1)
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

    @ViewBuilder
    private var viewBackground: some View {
        ZStack {
            Group {
                // When a light color scheme is active, `defaultBackgroundColor` and `overlayContentHidingBackgroundColor`
                // colors simulate color blending with the help of dynamic opacity.
                //
                // When the dark color scheme is active, no color blending is needed, and only `defaultBackgroundColor`
                // is visible (btw in dark mode both colors are the same),
                defaultBackgroundColor
                    .opacity(isDarkColorScheme ? 1.0 : viewModel.overlayContentHidingProgress)

                overlayContentHidingBackgroundColor
                    .opacity(isDarkColorScheme ? 0.0 : 1.0 - viewModel.overlayContentHidingProgress)
            }
            .ignoresSafeArea()
        }
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
