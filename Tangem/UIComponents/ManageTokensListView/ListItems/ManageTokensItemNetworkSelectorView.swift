//
//  ManageTokensItemNetworkSelectorView.swift
//  Tangem
//
//  Created by Andrew Son on 21/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import TangemUI

struct ManageTokensItemNetworkSelectorView: View {
    @ObservedObject var viewModel: ManageTokensItemNetworkSelectorViewModel

    let arrowWidth: Double

    @State private var size: CGSize = .zero

    /// How much arrow should extrude from the edge of the icon
    private let arrowExtrudeLength: CGFloat = 4

    var body: some View {
        HStack(spacing: 8) {
            ArrowView(
                position: viewModel.position,
                width: arrowWidth + arrowExtrudeLength,
                height: size.height,
                arrowCenterXOffset: -(arrowExtrudeLength / 2)
            )

            HStack(spacing: 8) {
                icon

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(viewModel.networkName.uppercased())
                        .style(Fonts.Bold.footnote, color: viewModel.networkNameForegroundColor)
                        .lineLimit(2)

                    if let contractName = viewModel.contractName {
                        Text(contractName)
                            .style(Fonts.Regular.caption1, color: viewModel.contractNameForegroundColor)
                            .padding(.leading, 2)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }

                Spacer(minLength: 0)

                if !viewModel.isReadonly {
                    Toggle("", isOn: $viewModel.isSelected)
                        .labelsHidden()
                        .tint(Colors.Control.checked)
                        .offset(x: 2)
                        .scaleEffect(0.8)
                }
            }
            .padding(.vertical, 16)
        }
        .contentShape(Rectangle())
        .onTapGesture {} // fix scroll/longpress conflict
        .onLongPressGesture(perform: viewModel.onCopy)
        .readGeometry(\.size, bindTo: $size)
    }

    var icon: some View {
        NetworkIcon(
            imageName: viewModel.isSelected ? viewModel.imageNameSelected : viewModel.imageName,
            isActive: viewModel.isSelected,
            isMainIndicatorVisible: viewModel.isMain,
            size: .init(bothDimensions: 22)
        )
    }
}

struct ManageTokensItemNetworkSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            ManageTokensItemNetworkSelectorView(
                viewModel: ManageTokensItemNetworkSelectorViewModel(
                    tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
                    isReadonly: false,
                    isSelected: .constant(false)
                ),
                arrowWidth: 40
            )

            ManageTokensItemNetworkSelectorView(
                viewModel: ManageTokensItemNetworkSelectorViewModel(
                    tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
                    isReadonly: false,
                    isSelected: .constant(true),
                    position: .last
                ),
                arrowWidth: 40
            )

            StatefulPreviewWrapper(false) {
                ManageTokensItemNetworkSelectorView(
                    viewModel: ManageTokensItemNetworkSelectorViewModel(
                        tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
                        isReadonly: false,
                        isSelected: $0
                    ),
                    arrowWidth: 40
                )
            }

            Spacer()
        }
    }
}
