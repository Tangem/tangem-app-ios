//
//  CustomTokenItemView.swift
//  Tangem
//
//  Created by Andrew Son on 19/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct CustomTokenItemView: View {
    let info: CustomTokenItemViewInfo
    let removeAction: (CustomTokenItemViewInfo) -> Void

    var body: some View {
        HStack(spacing: 12) {
            TokenIcon(
                tokenIconInfo: info.iconInfo,
                size: .init(bothDimensions: 36)
            )

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(info.name)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    Text(info.symbol)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }

                Text(Localization.commonCustom)
                    .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
            }

            Spacer(minLength: 16)

            Button {
                removeAction(info)
            } label: {
                Text(Localization.manageTokensRemove)
                    .style(Fonts.Bold.caption1, color: Colors.Text.primary1)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Colors.Button.secondary)
                    .cornerRadiusContinuous(20)
            }
        }
        .background(Colors.Background.primary)
        .padding(.all, 16)
    }
}

#Preview {
    let iconInfoBuilder = TokenIconInfoBuilder()
    let tokenItem = TokenItem.token(.sushiMock, .init(.polygon(testnet: false), derivationPath: nil))
    return CustomTokenItemView(
        info: .init(
            tokenItem: .blockchain(.init(.polygon(testnet: false), derivationPath: nil)),
            iconInfo: iconInfoBuilder.build(from: tokenItem, isCustom: true),
            name: tokenItem.name,
            symbol: tokenItem.currencySymbol
        ),
        removeAction: { _ in }
    )
}
