//
//  IconView.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher

struct IconView: View {
    private let url: URL?
    private let solidColor: Color?
    private let size: CGSize
    private let lowContrastBackgroundColor: UIColor

    // TODO: HACK - figure out why CachedAsyncImage is making Manage Tokens screen jump
    // TODO: on 16.2 on the first run of the first time this screen is opened
    private let forceKingfisher: Bool

    private let solidColorIconSizeRatio = 0.54

    private static var defaultLowContrastBackgroundColor: UIColor {
        UIColor.backgroundPrimary.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    }

    init(url: URL?, solidColor: Color?, size: CGSize, lowContrastBackgroundColor: UIColor = Self.defaultLowContrastBackgroundColor, forceKingfisher: Bool = false) {
        self.url = url
        self.solidColor = solidColor
        self.size = size
        self.lowContrastBackgroundColor = lowContrastBackgroundColor
        self.forceKingfisher = forceKingfisher
    }

    init(url: URL?, solidColor: Color?, sizeSettings: IconViewSizeSettings, lowContrastBackgroundColor: UIColor = Self.defaultLowContrastBackgroundColor, forceKingfisher: Bool = false) {
        self.init(url: url, solidColor: solidColor, size: sizeSettings.iconSize, lowContrastBackgroundColor: lowContrastBackgroundColor, forceKingfisher: forceKingfisher)
    }

    var body: some View {
        if let solidColor {
            solidColor
                .clipShape(Circle())
                .overlay(
                    Assets.star.image
                        .resizable()
                        .frame(
                            width: size.width * solidColorIconSizeRatio,
                            height: size.height * solidColorIconSizeRatio
                        )
                )
                .frame(size: size)
        } else {
            networkImage
        }
    }

    @ViewBuilder
    var networkImage: some View {
        if forceKingfisher {
            kfImage
        } else if #available(iOS 15.0, *) {
            cachedAsyncImage
        } else {
            kfImage
        }
    }

    @available(iOS 15.0, *)
    var cachedAsyncImage: some View {
        CachedAsyncImage(url: url, scale: UIScreen.main.scale) { phase in
            switch phase {
            case .empty:
                placeholder
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(size: size)
                    .cornerRadiusContinuous(5)
            case .failure:
                Circle()
                    .fill(Color.clear)
                    .frame(size: size)
                    .overlay(
                        Circle()
                            .stroke(Colors.Icon.informative, lineWidth: 1)
                    )
                    .cornerRadius(size.height / 2)
            @unknown default:
                EmptyView()
            }
        }
    }

    var kfImage: some View {
        KFImage(url)
            .appendProcessor(ContrastBackgroundImageProcessor(backgroundColor: lowContrastBackgroundColor))
            .cancelOnDisappear(true)
            .placeholder { CircleImageTextView(name: "", color: Colors.Button.secondary, size: size) }
            .fade(duration: 0.3)
            .cacheOriginalImage()
            .resizable()
            .scaledToFit()
            .frame(size: size)
            .cornerRadiusContinuous(5)
    }

    private var placeholder: some View {
        SkeletonView()
            .frame(size: size)
            .cornerRadius(size.height / 2)
    }
}

struct IconView_Preview: PreviewProvider {
    static var previews: some View {
        IconView(
            url: TokenIconURLBuilder().iconURL(id: "arbitrum-one", size: .small),
            solidColor: nil,
            size: CGSize(width: 40, height: 40)
        )
    }
}
