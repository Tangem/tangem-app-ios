//
//  MultiWalletCardHeaderView.swift
//  Tangem
//
//  Created by Andrew Son on 10/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MultiWalletCardHeaderView: View {
    @ObservedObject var viewModel: MultiWalletCardHeaderViewModel

    private let imageSize: CGSize = .init(width: 120, height: 106)
    private let horizontalSpacing: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.cardName)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    Text(viewModel.balance)
                        .multilineTextAlignment(.leading)
                        .scaledToFit()
                        .minimumScaleFactor(0.5)
                        .showSensitiveInformation(viewModel.showSensitiveInformation)
                        .skeletonable(isShown: viewModel.isLoadingBalance, size: .init(width: 102, height: 24), radius: 6)
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                        .frame(height: 34)

                    HStack(spacing: 6) {
                        Text(viewModel.numberOfCards)

                        if viewModel.isWalletImported {
                            Text("•")

                            Text(Localization.commonSeedPhrase)
                        }
                    }
                    .style(Fonts.Regular.caption2, color: Colors.Text.disabled)
                    .fixedSize()
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
    }

    private func leadingContentWidth(containerWidth: CGFloat) -> CGFloat {
        var trailingOffset: CGFloat = 0

        if viewModel.isWithCardImage {
            trailingOffset = imageSize.width + horizontalSpacing
        }

        return max(containerWidth - trailingOffset, 0.0)
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
                            MultiWalletCardHeaderView(viewModel: provider.models[index])
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
