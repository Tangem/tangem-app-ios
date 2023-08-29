//
//  LegacyCoinItemView.swift
//  Tangem
//
//  Created by Alexander Osokin on 17.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import BlockchainSdk

struct LegacyCoinItemView: View {
    @ObservedObject var model: LegacyCoinItemViewModel

    let arrowWidth: Double

    var icon: some View {
        NetworkIcon(
            imageName: model.selectedPublisher ? model.imageNameSelected : model.imageName,
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

                if !model.isReadonly {
                    Toggle("", isOn: $model.selectedPublisher)
                        .labelsHidden()
                        .toggleStyleCompat(Colors.Control.checked)
                        .offset(x: 2)
                        .scaleEffect(0.8)
                }
            }
            .padding(.vertical, 8)
        }
        .contentShape(Rectangle())
        .onTapGesture {} // fix scroll/longpress conflict
        .onLongPressGesture(perform: model.onCopy)
        .readGeometry(\.size, bindTo: $size)
    }
}

struct CurrencyItemView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            LegacyCoinItemView(
                model: LegacyCoinItemViewModel(
                    tokenItem: .blockchain(.ethereum(testnet: false)),
                    isReadonly: false,
                    isSelected: .constant(false)
                ),
                arrowWidth: 46
            )

            LegacyCoinItemView(
                model: LegacyCoinItemViewModel(
                    tokenItem: .blockchain(.ethereum(testnet: false)),
                    isReadonly: false,
                    isSelected: .constant(true),
                    position: .last
                ),
                arrowWidth: 46
            )

            StatefulPreviewWrapper(false) {
                LegacyCoinItemView(
                    model: LegacyCoinItemViewModel(
                        tokenItem: .blockchain(.ethereum(testnet: false)),
                        isReadonly: false,
                        isSelected: $0
                    ),
                    arrowWidth: 46
                )
            }

            Spacer()
        }
    }
}
