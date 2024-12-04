//
//  ActionButtonsSwapView.swift
//  TangemApp
//
//  Created by Viacheslav E. on 18.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemExpress

struct ActionButtonsSwapView: View {
    @ObservedObject var viewModel: ActionButtonsSwapViewModel

    var body: some View {
        content
            .scrollDismissesKeyboardCompat(.immediately)
            .animation(.easeInOut(duration: 0.2), value: viewModel.sourceToken)
            .animation(.easeOut, value: viewModel.destinationToken)
            .animation(.easeInOut, value: viewModel.tokenSelectorState)
            .animation(.easeInOut, value: viewModel.notificationInputs)
            .padding(.top, 10)
            .background(Colors.Background.tertiary.ignoresSafeArea())
            .disabled(viewModel.tokenSelectorState == .loading)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 14) {
                swapPair

                tokensListView
            }
            .padding(.horizontal, 16)
        }
    }

    private var swapPair: some View {
        VStack(spacing: 14) {
            ActionButtonsChooseTokenView(field: .source, selectedToken: $viewModel.sourceToken)

            if viewModel.isSourceTokenSelected {
                ActionButtonsChooseTokenView(field: .destination, selectedToken: $viewModel.destinationToken)
                    .transition(.notificationTransition)
            }
        }
        .overlay(content: expressTransitionProgress)
    }
}

private extension ActionButtonsSwapView {
    @ViewBuilder
    func expressTransitionProgress() -> some View {
        if viewModel.destinationToken != nil {
            Circle()
                .stroke(style: .init(lineWidth: 1))
                .foregroundStyle(Colors.Stroke.primary)
                .frame(size: .init(bothDimensions: 44))

            Circle()
                .foregroundStyle(Colors.Background.primary)
                .frame(size: .init(bothDimensions: 43))

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.primary1))
        }
    }

    @ViewBuilder
    var tokensListView: some View {
        switch viewModel.tokenSelectorState {
        case .initial, .loaded:
            tokenSelector
        case .loading:
            tokenSelectorStub
        case .noAvailablePairs:
            notificationView
            tokenSelector
        case .refreshRequired:
            notificationView
        case .readyToSwap:
            EmptyView()
        }
    }

    var notificationView: some View {
        ForEach(viewModel.notificationInputs) {
            NotificationView(input: $0)
                .transition(.opacity.animation(.easeInOut))
        }
    }

    var tokenSelector: some View {
        TokenSelectorView(
            viewModel: viewModel.tokenSelectorViewModel,
            tokenCellContent: { token in
                ActionButtonsTokenSelectItemView(model: token) {
                    viewModel.handleViewAction(.didTapToken(token))
                }
                .padding(.vertical, 16)
            },
            emptySearchContent: {
                Text(viewModel.tokenSelectorViewModel.strings.emptySearchMessage)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.center)
                    .animation(.default, value: viewModel.tokenSelectorViewModel.searchText)
                    .frame(width: 252)
            }
        )
    }
}

// MARK: - Token selector stub

private extension ActionButtonsSwapView {
    var tokenSelectorStub: some View {
        GroupedSection(
            [0, 1, 2],
            content: { _ in
                tokenSelectorStubItem
                    .padding(.vertical, 16)
            },
            header: {
                DefaultHeaderView(Localization.exchangeTokensAvailableTokensHeader)
                    .frame(height: 18)
                    .padding(.init(top: 14, leading: 0, bottom: 10, trailing: 0))
            }
        )
        .settings(\.backgroundColor, Colors.Background.action)
    }

    var tokenSelectorStubItem: some View {
        HStack(spacing: 0) {
            tokenIconStub

            tokenInfoStub
                .padding(.leading, 8)

            Spacer()

            balanceInfoStub
        }
    }

    var tokenIconStub: some View {
        SkeletonView()
            .frame(size: .init(bothDimensions: 36))
            .cornerRadius(18, corners: .allCorners)
            .overlay(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 2)
                        .frame(size: .init(bothDimensions: 16))
                        .foregroundStyle(Colors.Background.action)

                    SkeletonView()
                        .frame(size: .init(bothDimensions: 14))
                        .cornerRadius(7, corners: .allCorners)
                }
                .offset(x: 4, y: -4)
            }
    }

    var tokenInfoStub: some View {
        VStack(alignment: .leading, spacing: 8) {
            makeSkeleton(width: 70)

            makeSkeleton(width: 52)
        }
    }

    var balanceInfoStub: some View {
        VStack(alignment: .leading, spacing: 8) {
            makeSkeleton(width: 40)

            makeSkeleton(width: 40)
        }
    }

    func makeSkeleton(width: CGFloat, height: CGFloat = 12, cornerRadius: CGFloat = 3) -> some View {
        SkeletonView()
            .frame(width: width, height: height)
            .cornerRadiusContinuous(cornerRadius)
    }
}
