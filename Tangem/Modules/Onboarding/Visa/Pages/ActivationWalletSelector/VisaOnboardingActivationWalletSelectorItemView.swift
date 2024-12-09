//
//  VisaOnboardingActivationWalletSelectorItemView.swift
//  Tangem
//
//  Created by Andrew Son on 03.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct VisaOnboardingActivationWalletSelectorItemView: View {
    let item: Option
    let selected: Bool
    let tapAction: () -> Void

    var body: some View {
        Button {
            withAnimation {
                tapAction()
            }
        } label: {
            HStack(spacing: 12) {
                item.icon
                    .frame(size: CGSize(bothDimensions: 36))

                Text(item.title)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Spacer()
            }
            .padding(14)
        }
        .if(selected, transform: { view in
            view
                .overlay(content: {
                    RoundedRectangle(cornerSize: .init(width: 14, height: 14))
                        .stroke(lineWidth: 2)
                        .foregroundStyle(Colors.Icon.accent)
                        .background {
                            RoundedRectangle(cornerSize: .init(width: 16, height: 16))
                                .stroke(lineWidth: 3)
                                .padding(-2)
                                .foregroundStyle(Colors.Icon.accent.opacity(0.5))
                        }
                })
                .zIndex(100)
        })
    }
}

extension VisaOnboardingActivationWalletSelectorItemView {
    enum Option: String, Identifiable, Hashable, CaseIterable {
        case tangemWallet
        case otherWallet

        var id: String { rawValue }

        var title: String {
            switch self {
            case .tangemWallet:
                return "Tangem Wallet"
            case .otherWallet:
                return "Other wallet"
            }
        }

        @ViewBuilder
        var icon: some View {
            switch self {
            case .otherWallet:
                Assets.wallet36.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.informative)
            case .tangemWallet:
                Assets.tangemIcon36.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.primary1)
            }
        }
    }
}
