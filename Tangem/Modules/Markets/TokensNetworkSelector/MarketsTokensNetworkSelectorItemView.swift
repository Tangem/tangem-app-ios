//
//  MarketsTokensNetworkSelectorItemView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 12.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokensNetworkSelectorItemView: View {
    @ObservedObject var viewModel: MarketsTokensNetworkSelectorItemViewModel

    @State private var size: CGSize = .zero

    /// How much arrow should extrude from the edge of the icon
    private let arrowExtrudeLength: CGFloat = 4
    private let arrowWidth: Double = Constants.iconWidth

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

                Button {
                    viewModel.onSelectedTapAction()
                } label: {
                    selectedCheckmark
                }
                .disabled(viewModel.isReadonly)
            }
            .padding(.vertical, 16)
        }
        .contentShape(Rectangle())
        .readGeometry(\.size, bindTo: $size)
    }

    // MARK: - Private UI

    private var icon: some View {
        NetworkIcon(
            imageName: viewModel.iconImageName,
            isActive: viewModel.isSelected && !viewModel.isReadonly,
            isDisabled: viewModel.isReadonly,
            isMainIndicatorVisible: viewModel.isMain,
            size: .init(bothDimensions: Constants.iconWidth)
        )
    }

    private var selectedCheckmark: some View {
        viewModel
            .checkedImage
            .frame(size: Constants.checkedSelectedIconSize)
    }
}

extension MarketsTokensNetworkSelectorItemView {
    enum Constants {
        static let iconWidth: Double = 22
        static let checkedSelectedIconSize = CGSize(bothDimensions: 24)
    }
}

struct MarketsTokensNetworkSelectorItemView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(itemsList(count: 1, isSelected: .constant(Bool.random())), id: \.id) { viewModel in
                    StatefulPreviewWrapper(false) { _ in
                        MarketsTokensNetworkSelectorItemView(viewModel: viewModel)
                    }
                }

                Spacer()
            }
        }
    }

    private static func itemsList(count: Int, isSelected: Binding<Bool>) -> [MarketsTokensNetworkSelectorItemViewModel] {
        var viewModels = [MarketsTokensNetworkSelectorItemViewModel]()
        for i in 0 ..< count {
            viewModels.append(MarketsTokensNetworkSelectorItemViewModel(
                tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
                isReadonly: false,
                isSelected: isSelected,
                position: i == (count - 1) ? .last : i == 0 ? .first : .middle
            ))
        }
        return viewModels
    }
}
