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

    let arrowWidth: Double

    var icon: some View {
        NetworkIcon(
            imageName: model.selectedPublisher ? model.imageNameSelected : model.imageName,
            isActive: model.selectedPublisher,
            isMainIndicatorVisible: model.isMain
        )
    }

    @State private var size: CGSize = .zero

    var body: some View {
        HStack(spacing: 6) {
            ArrowView(position: model.position, width: arrowWidth, height: size.height)

            HStack(spacing: 0) {
                icon
                    .padding(.trailing, 4)

                HStack(alignment: .top, spacing: 2) {
                    Text(model.networkName.uppercased())
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(model.networkNameForegroundColor)
                        .lineLimit(2)

                    if let contractName = model.contractName {
                        Text(contractName)
                            .font(.system(size: 14))
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
}

struct WelcomeTokenListItemView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            WelcomeTokenListItemView(
                model: WelcomeTokenListItemViewModel(
                    tokenItem: .blockchain(.ethereum(testnet: false)),
                    isSelected: .constant(false)
                ),
                arrowWidth: 46
            )

            WelcomeTokenListItemView(
                model: WelcomeTokenListItemViewModel(
                    tokenItem: .blockchain(.ethereum(testnet: false)),
                    isSelected: .constant(true),
                    position: .last
                ),
                arrowWidth: 46
            )

            StatefulPreviewWrapper(false) {
                WelcomeTokenListItemView(
                    model: WelcomeTokenListItemViewModel(
                        tokenItem: .blockchain(.ethereum(testnet: false)),
                        isSelected: $0
                    ),
                    arrowWidth: 46
                )
            }

            Spacer()
        }
    }
}
