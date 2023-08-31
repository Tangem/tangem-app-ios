//
//  TokenIconView.swift
//  Tangem
//
//  Created by Alexander Osokin on 31.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Kingfisher
import SwiftUI

@available(*, deprecated, message: "Use `IconView` instead")
struct TokenIconView: View {
    private let viewModel: TokenIconViewModel
    private let size: CGSize

    private let networkIconSize: CGSize
    private let networkIconBorderWidth: Double
    private let networkIconOffset: CGSize

    init(viewModel: TokenIconViewModel, sizeSettings: IconViewSizeSettings = .tokenItem) {
        self.viewModel = viewModel
        size = sizeSettings.iconSize
        networkIconSize = sizeSettings.networkIconSize
        networkIconBorderWidth = sizeSettings.networkIconBorderWidth
        networkIconOffset = sizeSettings.networkIconOffset
    }

    var body: some View {
        KFImage(viewModel.imageURL)
            .placeholder { placeholder }
            .fade(duration: 0.3)
            .cacheOriginalImage()
            .resizable()
            .scaledToFit()
            .frame(size: size)
            .overlay(networkIcon.offset(networkIconOffset), alignment: .topTrailing)
    }

    @ViewBuilder
    private var networkIcon: some View {
        if let iconName = viewModel.blockchainIconName {
            NetworkIcon(
                imageName: iconName,
                isMainIndicatorVisible: false,
                size: networkIconSize
            )
            .background(
                Color.white
                    .clipShape(Circle())
                    .frame(size: networkIconSize + CGSize(width: 2 * networkIconBorderWidth, height: 2 * networkIconBorderWidth))
            )
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        CircleImageTextView(name: viewModel.name, color: Colors.Icon.inactive, size: size)
    }
}

struct TokenIconView_Preview: PreviewProvider {
    static let viewModel = TokenIconViewModel(tokenItem: .blockchain(.gnosis))
    static let tokenViewModel = TokenIconViewModel(id: "stellar", name: "Stellar", style: .token(Tokens.ethereumFill.name))
    static var previews: some View {
        VStack(spacing: 16) {
            TokenIconView(viewModel: viewModel)

            TokenIconView(viewModel: tokenViewModel, sizeSettings: .tokenDetails)

            TokenIconView(
                viewModel: tokenViewModel,
                sizeSettings: .receive
            )
        }
    }
}
