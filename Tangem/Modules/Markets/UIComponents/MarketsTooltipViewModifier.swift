//
//  MarketsTooltipViewModifier.swift
//  Tangem
//
//  Created by skibinalexander on 13.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTooltipViewModifier: ViewModifier {
    // MARK: - Utilits

    @AppStorage(StorageKeys.tooltipWasShown.rawValue) private var tooltipWasShown: Bool = false

    // MARK: - Pivate Properties

    private(set) var needAppearTooltipView: Binding<Bool>

    // MARK: - UI

    func body(content: Content) -> some View {
        ZStack {
            content

            if needAppearTooltipView.wrappedValue {
                backgroundView

                tooltipView
            }
        }
    }

    // MARK: - Private Implementation

    private var backgroundView: some View {
        Color.black
            .ignoresSafeArea(.all)
            .opacity(0.4)
    }

    private var tooltipView: some View {
        VStack(spacing: .zero) {
            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.marketsTooltipTitle)
                    .lineLimit(1)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Text(Localization.marketsTooltipMessage)
                    .lineLimit(2)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
            }
            .defaultRoundedBackground()

            Triangle()
                .foregroundStyle(Colors.Background.action)
                .frame(size: .init(width: 20, height: 8))
                .rotationEffect(.degrees(180))
        }
        .padding(.horizontal, 64)
        .padding(.bottom, 96)
    }
}

extension View {
    func marketsTipViewModifier(with needAppearTooltipView: Binding<Bool>) -> some View {
        modifier(MarketsTooltipViewModifier(needAppearTooltipView: needAppearTooltipView))
    }
}

private extension MarketsTooltipViewModifier {
    enum StorageKeys: String, RawRepresentable {
        case tooltipWasShown = "tangem_markets_tooltip_was_shown"
    }
}
