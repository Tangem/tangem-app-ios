//
//  MainHeaderView.swift
//  Tangem
//
//  Created by Andrew Son on 10/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainHeaderView: View {
    @ObservedObject var viewModel: MainHeaderViewModel

    private let imageSize: CGSize = .init(width: 120, height: 106)
    private let horizontalSpacing: CGFloat = 6
    private let cornerRadius = 14.0

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                let contentSettings = contentSettings(containerWidth: proxy.size.width)

                VStack(alignment: .leading, spacing: 0) {
                    titleView

                    Spacer(minLength: 0)

                    if viewModel.isUserWalletLocked {
                        Colors.Field.primary
                            .frame(width: 102, height: 24)
                            .cornerRadiusContinuous(6)
                            .padding(.vertical, 5)
                    } else {
                        BalanceTitleView(balance: viewModel.balance, isLoading: viewModel.isLoadingFiatBalance)
                    }

                    Spacer(minLength: 10)

                    subtitleText
                }
                .lineLimit(1)
                .padding(.top, 14)
                .padding(.bottom, 12)
                .frame(width: contentSettings.leadingContentWidth, height: imageSize.height, alignment: .leading)

                if contentSettings.shouldShowTrailingContent {
                    Spacer(minLength: horizontalSpacing)

                    // A transparent 1px image is used to preserve the structural identity of the view,
                    // otherwise visual glitches may ocurr during the header swipe animation
                    //
                    // Do not replace nil coalescing operator here with any kind of operators
                    // that breaks the view's structural identity (`if`, `switch`, etc)
                    Image(viewModel.cardImage?.name ?? Assets.clearColor1px.name)
                        .frame(size: imageSize)
                }
            }
        }
        .frame(height: imageSize.height)
        .padding(.horizontal, 14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(cornerRadius)
        .previewContentShape(cornerRadius: cornerRadius)
    }

    @ViewBuilder private var titleView: some View {
        Text(viewModel.userWalletName)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
    }

    @ViewBuilder private var subtitleText: some View {
        Group {
            if viewModel.subtitleContainsSensitiveInfo {
                SensitiveText(viewModel.subtitleInfo.messages.first ?? "")
            } else {
                HStack(spacing: 6) {
                    ForEach(viewModel.subtitleInfo.messages, id: \.self) { message in
                        Text(message)

                        if message != viewModel.subtitleInfo.messages.last {
                            SubtitleSeparator()
                        }
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

    private func calculateTextWidth(_ text: NSAttributedString) -> CGFloat {
        return text.string
            .size(withAttributes: text.attributes(at: 0, effectiveRange: nil))
            .width
    }

    private func widthForBalanceWithImage(containerWidth: CGFloat) -> CGFloat {
        let imageWidth = viewModel.cardImage != nil ? imageSize.width : 0
        return containerWidth - imageWidth - horizontalSpacing
    }

    private func contentSettings(containerWidth: CGFloat) -> (leadingContentWidth: CGFloat, shouldShowTrailingContent: Bool) {
        let balanceWidth = calculateTextWidth(viewModel.balance)

        let widthForBalanceWithImage = widthForBalanceWithImage(containerWidth: containerWidth)
        if balanceWidth > widthForBalanceWithImage {
            return (containerWidth, false)
        }

        return (max(widthForBalanceWithImage, 0), true)
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
