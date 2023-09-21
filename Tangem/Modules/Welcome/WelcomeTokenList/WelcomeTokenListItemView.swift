//
//  WelcomeTokenListItemView.swift
//  Tangem
//
//  Created by skibinalexander on 18.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeTokenListItemView: View {
    @ObservedObject var model: WelcomeTokenListItemViewModel

    @State private var size: CGSize = .zero

    var body: some View {
        HStack(spacing: 6) {
            ArrowView(position: model.position, width: Constants.arrowWidth, height: size.height)

            HStack(spacing: 0) {
                icon
                    .padding(.trailing, 4)

                HStack(alignment: .top, spacing: 2) {
                    Text(model.networkName.uppercased())
                        .font(Fonts.Bold.footnote)
                        .foregroundColor(model.networkNameForegroundColor)
                        .lineLimit(2)

                    if let contractName = model.contractName {
                        Text(contractName)
                            .font(Fonts.Regular.footnote)
                            .foregroundColor(model.contractNameForegroundColor)
                            .padding(.leading, 2)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
        .contentShape(Rectangle())
        .readGeometry(\.size, bindTo: $size)
    }

    var icon: some View {
        NetworkIcon(
            imageName: model.selectedPublisher ? model.imageNameSelected : model.imageName,
            isActive: model.selectedPublisher,
            isMainIndicatorVisible: model.isMain
        )
    }
}

private extension WelcomeTokenListItemView {
    enum Constants {
        static let arrowWidth: Double = 46
    }
}

struct WelcomeTokenListItemView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            WelcomeTokenListItemView(
                model: WelcomeTokenListItemViewModel(
                    tokenItem: .blockchain(.ethereum(testnet: false)),
                    isSelected: .constant(false)
                )
            )

            WelcomeTokenListItemView(
                model: WelcomeTokenListItemViewModel(
                    tokenItem: .blockchain(.ethereum(testnet: false)),
                    isSelected: .constant(true),
                    position: .last
                )
            )

            StatefulPreviewWrapper(false) {
                WelcomeTokenListItemView(
                    model: WelcomeTokenListItemViewModel(
                        tokenItem: .blockchain(.ethereum(testnet: false)),
                        isSelected: $0
                    )
                )
            }

            Spacer()
        }
    }
}
