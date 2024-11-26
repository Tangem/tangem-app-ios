//
//  OnrampPaymentMethodRowView.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampPaymentMethodRowView: View {
    let data: OnrampPaymentMethodRowViewData

    var body: some View {
        Button(action: data.action) {
            content
        }
        .buttonStyle(.plain)
    }

    private var content: some View {
        HStack(spacing: 12) {
            OnrampPaymentMethodIconView(url: data.iconURL)

            titleView

            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .overlay { overlay }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var overlay: some View {
        if data.isSelected {
            Color.clear.overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Colors.Icon.accent, lineWidth: 1)
            }
            .padding(1)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Colors.Icon.accent.opacity(0.15), lineWidth: 2.5)
            }
            .padding(2.5)
        }
    }

    private var titleView: some View {
        Text(data.name)
            .style(
                Fonts.Bold.subheadline,
                color: data.isSelected ? Colors.Text.primary1 : Colors.Text.secondary
            )
            .lineLimit(1)
    }
}

#Preview {
    OnrampPaymentMethodRowView(data: .init(id: "card", name: "Card", iconURL: nil, isSelected: true, action: {}))
}
