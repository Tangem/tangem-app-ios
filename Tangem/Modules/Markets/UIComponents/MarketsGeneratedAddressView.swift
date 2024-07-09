//
//  MarketsGeneratedAddressView.swift
//  Tangem
//
//  Created by skibinalexander on 08.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsGeneratedAddressView: View {
    var body: some View {
        HStack(spacing: 12) {
            Assets
                .tangemIcon
                .image
                .resizable()
                .renderingMode(.template)
                .frame(width: 20, height: 20)
                .foregroundColor(Colors.Icon.primary1)

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey("To generate addresses for selected networks, you need to attach a Tangem card"))
                    .multilineTextAlignment(.leading)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .infinityFrame(axis: .horizontal, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Colors.Button.disabled)
        )
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }
}
