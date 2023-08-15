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

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.userWalletName)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    Text(viewModel.balance)
                        .multilineTextAlignment(.leading)
                        .truncationMode(.middle)
                        .scaledToFit()
                        .minimumScaleFactor(0.5)
                        .showSensitiveInformation(viewModel.showSensitiveInformation)
                        .skeletonable(
                            isShown: viewModel.isUserWalletLocked || viewModel.isLoadingFiatBalance,
                            size: .init(width: 102, height: 24),
                            radius: 6
                        )
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                        .frame(minHeight: 34)

                    if viewModel.isUserWalletLocked {
                        subtitleText
                    } else {
                        subtitleText
                            .showSensitiveInformation(viewModel.showSensitiveSubtitleInformation)
                            .skeletonable(isShown: viewModel.isLoadingSubtitle, size: .init(width: 52, height: 12), radius: 3)
                    }
                }
                .lineLimit(1)
                .frame(width: leadingContentWidth(containerWidth: proxy.size.width), alignment: .leading)
                .padding(.vertical, 12)

                if let cardImage = viewModel.cardImage {
                    Spacer()
                        .frame(minWidth: horizontalSpacing)

                    cardImage.image
                        .frame(size: imageSize)
                }
            }
        }
        .frame(height: imageSize.height)
        .padding(.horizontal, 14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
        .previewContentShape(cornerRadius: 14)
    }

    private var subtitleText: some View {
        Text(viewModel.subtitleInfo.message)
            .style(
                viewModel.subtitleInfo.formattingOption.font,
                color: viewModel.subtitleInfo.formattingOption.textColor
            )
            .truncationMode(.middle)
    }

    private func leadingContentWidth(containerWidth: CGFloat) -> CGFloat {
        var trailingOffset: CGFloat = 0

        if viewModel.cardImage != nil {
            trailingOffset = imageSize.width + horizontalSpacing
        }

        return max(containerWidth - trailingOffset, 0.0)
    }
}

private extension View {
    @ViewBuilder
    func previewContentShape(cornerRadius: Double) -> some View {
        if #available(iOS 15.0, *) {
            self
                .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            self
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
            }
        }
    }

    static var previews: some View {
        CardHeaderPreview()
    }
}
