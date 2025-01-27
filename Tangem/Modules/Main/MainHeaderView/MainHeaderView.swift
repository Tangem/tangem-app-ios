//
//  MainHeaderView.swift
//  Tangem
//
//  Created by Andrew Son on 10/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MainHeaderView: View {
    @ObservedObject var viewModel: MainHeaderViewModel

    private let imageSize: CGSize = .init(width: 120, height: 106)
    private let horizontalSpacing: CGFloat = 6
    private let cornerRadius = 14.0

    @State private var containerSize: CGSize = .zero
    @State private var balanceTextSize: CGSize = .zero

    var body: some View {
        let contentSettings = contentSettings(containerWidth: containerSize.width)

        return HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                titleView

                Spacer(minLength: 6)

                if viewModel.isUserWalletLocked {
                    Colors.Field.primary
                        .frame(width: 102, height: 24)
                        .cornerRadiusContinuous(6)
                        .padding(.vertical, 5)
                } else {
                    LoadableTokenBalanceView(
                        state: viewModel.balance,
                        style: .init(font: Fonts.Regular.title1, textColor: Colors.Text.primary1),
                        loader: .init(size: .init(width: 102, height: 24), cornerRadius: 6)
                    )
                    .readGeometry(\.size, bindTo: $balanceTextSize)
                }

                Spacer(minLength: 10)

                HStack {
                    subtitleText

                    Spacer()
                }
            }
            .lineLimit(1)
            .padding(.vertical, 12)
        }
        .background(alignment: .bottom, content: {
            HStack {
                Spacer(minLength: horizontalSpacing)

                // A transparent 1px image is used to preserve the structural identity of the view,
                // otherwise visual glitches may ocurr during the header swipe animation
                //
                // Do not replace nil coalescing operator here with any kind of operators
                // that breaks the view's structural identity (`if`, `switch`, etc)
                Image(viewModel.cardImage?.name ?? Assets.clearColor1px.name)
                    .frame(size: imageSize)
            }
            .hidden(!contentSettings.shouldShowTrailingContent)
        })
        .readGeometry(\.size, bindTo: $containerSize)
        .padding(.horizontal, 14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(cornerRadius)
        .previewContentShape(cornerRadius: cornerRadius)
        .frame(minHeight: imageSize.height)
    }

    @ViewBuilder private var titleView: some View {
        Text(viewModel.userWalletName)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
    }

    @ViewBuilder private var subtitleText: some View {
        Group {
            HStack(spacing: 6) {
                ForEach(viewModel.subtitleInfo.messages, id: \.self) { message in
                    if viewModel.subtitleContainsSensitiveInfo {
                        SensitiveText(message)
                    } else {
                        Text(message)
                    }

                    if message != viewModel.subtitleInfo.messages.last {
                        SubtitleSeparator()
                    }
                }
            }
        }
        .style(
            viewModel.subtitleInfo.formattingOption.font,
            color: viewModel.subtitleInfo.formattingOption.textColor
        )
        .truncationMode(.middle)
        .modifier(if: !viewModel.isUserWalletLocked) {
            $0.skeletonable(isShown: viewModel.isLoadingSubtitle, size: .init(width: 52, height: 12), radius: 3)
        }
    }

    private func widthForBalanceWithImage(containerWidth: CGFloat) -> CGFloat {
        if viewModel.cardImage == nil {
            return containerWidth
        }

        return containerWidth - imageSize.width - horizontalSpacing
    }

    private func contentSettings(containerWidth: CGFloat) -> (leadingContentSize: CGSize, shouldShowTrailingContent: Bool) {
        let widthForBalanceWithImage = widthForBalanceWithImage(containerWidth: containerWidth)
        if balanceTextSize.width > widthForBalanceWithImage {
            return (.init(width: containerWidth, height: balanceTextSize.height), false)
        }

        let hasImage = viewModel.cardImage != nil
        let balanceAvailableWidth = max(widthForBalanceWithImage, 0)
        return (.init(width: balanceAvailableWidth, height: balanceTextSize.height), hasImage)
    }
}

private extension MainHeaderView {
    struct SubtitleSeparator: View {
        var body: some View {
            Colors.Icon.informative
                .clipShape(Circle())
                .frame(size: .init(bothDimensions: 2.5))
        }
    }
}

struct CardHeaderView_Previews: PreviewProvider {
    struct CardHeaderPreview: View {
        @ObservedObject var provider: FakeCardHeaderPreviewProvider = .init()

        var body: some View {
            ZStack {
                Colors.Background.secondary
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    ForEach(
                        provider.models.indices,
                        id: \.self,
                        content: { index in
                            MainHeaderView(viewModel: provider.models[index])
                                .onTapGesture {
                                    let provider = provider.infoProviders[index]
                                    provider.tapAction(provider)
                                }
                        }
                    )
                }
                .padding()
            }
        }
    }

    static var previews: some View {
        CardHeaderPreview()
    }
}
