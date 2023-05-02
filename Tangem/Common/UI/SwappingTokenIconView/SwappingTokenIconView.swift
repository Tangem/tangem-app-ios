//
//  SwappingTokenIcon.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher

struct SwappingTokenIconView: View {
    private let viewModel: SwappingTokenIconViewModel
    private var action: (() -> Void)?

    init(viewModel: SwappingTokenIconViewModel) {
        self.viewModel = viewModel
    }

    private let imageSize = CGSize(width: 36, height: 36)
    private let networkIconSize = CGSize(width: 16, height: 16)
    private let chevronIconSize = CGSize(width: 9, height: 9)

    private var chevronYOffset: CGFloat {
        imageSize.height / 2 - chevronIconSize.height / 2
    }

    private var isTappable: Bool {
        action != nil
    }

    var body: some View {
        Button(action: { action?() }) {
            HStack(alignment: .top, spacing: 4) {
                mainContent

                Assets.chevron.image
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)
                    .frame(size: chevronIconSize)
                    .offset(y: chevronYOffset)
                    /// View have to keep size of the view same for both cases
                    .opacity(isTappable ? 1 : 0)
            }
        }
        .disabled(!isTappable)
    }

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.state {
        case .loading:
            VStack(spacing: 4) {
                SkeletonView()
                    .frame(size: imageSize)
                    .cornerRadius(imageSize.height / 2)

                SkeletonView()
                    .frame(width: 30, height: 14)
            }

        case .loaded(let imageURL, let networkURL, let symbol):
            VStack(spacing: 4) {
                image(imageURL: imageURL, networkURL: networkURL)

                Text(symbol)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
            }
        }
    }

    private func image(imageURL: URL, networkURL: URL?) -> some View {
        ZStack(alignment: .topTrailing) {
            IconView(url: imageURL, size: imageSize)

            if let networkIcon = networkURL {
                IconView(url: networkIcon, size: networkIconSize)
                    .frame(size: networkIconSize)
                    .padding(.all, 1)
                    .background(Colors.Background.primary)
                    .cornerRadius(networkIconSize.height / 2)
                    .offset(x: 6, y: -6)
            }
        }
    }
}

// MARK: - Setupable

extension SwappingTokenIconView: Setupable {
    func onTap(_ action: (() -> Void)?) -> Self {
        map { $0.action = action }
    }
}

struct SwappingTokenIcon_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            SwappingTokenIconView(viewModel: SwappingTokenIconViewModel(state: .loading))

            SwappingTokenIconView(viewModel: SwappingTokenIconViewModel(state: .loading))
                .onTap {}

            SwappingTokenIconView(
                viewModel: SwappingTokenIconViewModel(
                    state: .loaded(
                        imageURL: TokenIconURLBuilderMock().iconURL(id: "dai", size: .large),
                        networkURL: TokenIconURLBuilderMock().iconURL(id: "ethereum", size: .small),
                        symbol: "MATIC"
                    )
                )
            )
            .onTap {}

            SwappingTokenIconView(
                viewModel: SwappingTokenIconViewModel(
                    state: .loaded(
                        imageURL: TokenIconURLBuilderMock().iconURL(id: "dai", size: .large),
                        networkURL: TokenIconURLBuilderMock().iconURL(id: "ethereum", size: .small),
                        symbol: "MATIC"
                    )
                )
            )
        }
    }
}
