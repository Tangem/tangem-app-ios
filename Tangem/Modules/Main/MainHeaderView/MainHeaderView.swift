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
    private let cornerRadius = 14.0

    @State private var containerSize: CGSize = .zero
    @State private var balanceTextSize: CGSize = .zero

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                titleView

                Spacer(minLength: 6)

                if viewModel.isUserWalletLocked {
                    Colors.Field.primary
                        .frame(width: 102, height: 24)
                        .cornerRadiusContinuous(6)
                        .padding(.vertical, 5)
                } else {
                    BalanceTitleView(balance: viewModel.balance, isLoading: viewModel.isLoadingFiatBalance)
                        .overlay(
                            SensitiveText(viewModel.balance)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: true, vertical: true)
                                .readGeometry(\.size, bindTo: $balanceTextSize)
                                .opacity(0.0),
                            alignment: .leading
                        )
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
