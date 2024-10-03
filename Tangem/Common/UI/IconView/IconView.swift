//
//  IconView.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher

struct IconView<Placeholder: View>: View {
    private let url: URL?
    private let size: CGSize
    private let cornerRadius: CGFloat
    private let lowContrastBackgroundColor: UIColor

    // TODO: HACK - figure out why CachedAsyncImage is making Manage Tokens screen jump
    // TODO: on 16.2 on the first run of the first time this screen is opened
    private let forceKingfisher: Bool

    private let placeholder: Placeholder

    init(
        url: URL?,
        size: CGSize,
        cornerRadius: CGFloat = IconViewDefaults.cornerRadius,
        lowContrastBackgroundColor: UIColor = IconViewDefaults.lowContrastBackgroundColor,
        forceKingfisher: Bool = false,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.url = url
        self.size = size
        self.cornerRadius = cornerRadius
        self.lowContrastBackgroundColor = lowContrastBackgroundColor
        self.forceKingfisher = forceKingfisher
        self.placeholder = placeholder()
    }

    init(
        url: URL?,
        sizeSettings: IconViewSizeSettings,
        cornerRadius: CGFloat = IconViewDefaults.cornerRadius,
        lowContrastBackgroundColor: UIColor = IconViewDefaults.lowContrastBackgroundColor,
        forceKingfisher: Bool = false,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.init(
            url: url,
            size: sizeSettings.iconSize,
            cornerRadius: cornerRadius,
            lowContrastBackgroundColor: lowContrastBackgroundColor,
            forceKingfisher: forceKingfisher,
            placeholder: placeholder
        )
    }

    var body: some View {
        if forceKingfisher {
            kfImage
        } else {
            cachedAsyncImage
        }
    }

    var cachedAsyncImage: some View {
        CachedAsyncImage(url: url, scale: UIScreen.main.scale) { phase in
            switch phase {
            case .empty:
                loadingPlaceholder
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(size: size)
                    .cornerRadiusContinuous(cornerRadius)
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
            .placeholder { placeholder }
            .fade(duration: 0.3)
            .cacheOriginalImage()
            .resizable()
            .scaledToFit()
            .frame(size: size)
            .cornerRadiusContinuous(cornerRadius)
    }

    private var loadingPlaceholder: some View {
        SkeletonView()
            .frame(size: size)
            .cornerRadius(size.height / 2)
    }
}

// Extension to support default placeholder

extension IconView where Placeholder == CircleImageTextView {
    init(
        url: URL?,
        size: CGSize,
        cornerRadius: CGFloat = IconViewDefaults.cornerRadius,
        lowContrastBackgroundColor: UIColor = IconViewDefaults.lowContrastBackgroundColor,
        forceKingfisher: Bool = false
    ) {
        self.init(
            url: url,
            size: size,
            cornerRadius: cornerRadius,
            lowContrastBackgroundColor: lowContrastBackgroundColor,
            forceKingfisher: forceKingfisher
        ) {
            CircleImageTextView(name: "", color: Colors.Button.secondary, size: size)
        }
    }

    init(url: URL?, sizeSettings: IconViewSizeSettings, cornerRadius: CGFloat = IconViewDefaults.cornerRadius, lowContrastBackgroundColor: UIColor = IconViewDefaults.lowContrastBackgroundColor, forceKingfisher: Bool = false) {
        self.init(
            url: url,
            sizeSettings: sizeSettings,
            cornerRadius: cornerRadius,
            lowContrastBackgroundColor: lowContrastBackgroundColor,
            forceKingfisher: forceKingfisher
        ) {
            CircleImageTextView(name: "", color: Colors.Button.secondary, size: sizeSettings.iconSize)
        }
    }
}

private enum IconViewDefaults {
    static let cornerRadius: CGFloat = 5
    static let lowContrastBackgroundColor = UIColor.backgroundPrimary
        .resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
}

struct IconView_Preview: PreviewProvider {
    static var previews: some View {
        IconView(
            url: IconURLBuilder().tokenIconURL(id: "arbitrum-one", size: .small),
            size: CGSize(width: 40, height: 40)
        )
    }
}
