//
//  PendingExpressTransactionView.swift
//  Tangem
//
//  Created by Andrew Son on 29/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct PendingExpressTransactionView: View {
    var info: Info

    private let networkIconSize = CGSize(bothDimensions: 18)

    var body: some View {
        Button {
            info.action(info.id)
        } label: {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(info.title)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                HStack(spacing: 6) {
                    TokenIcon(
                        tokenIconInfo: info.sourceIconInfo,
                        size: networkIconSize,
                        isWithOverlays: false
                    )

                    SensitiveText(info.sourceAmountText)
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                    Assets.arrowRightMini.image
                        .renderingMode(.template)
                        .resizable()
                        .frame(size: .init(bothDimensions: 12))
                        .foregroundColor(Colors.Icon.informative)

                    TokenIcon(
                        tokenIconInfo: info.destinationIconInfo,
                        size: networkIconSize,
                        isWithOverlays: false
                    )

                    Text(info.destinationAmountText)
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
                }
            }

            Spacer(minLength: 6)

            stateIcon

            Assets.chevronRight.image
                .foregroundColor(Colors.Icon.informative)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch info.state {
        case .inProgress:
            EmptyView()
        case .warning:
            Assets.warningIcon.image
                .frame(size: .init(bothDimensions: 20))
        case .error:
            Assets.redCircleWarning.image
                .frame(size: .init(bothDimensions: 20))
        }
    }
}

extension PendingExpressTransactionView {
    struct Info: Identifiable, Equatable {
        let id: String
        let title: String
        let sourceIconInfo: TokenIconInfo
        let sourceAmountText: String
        let destinationIconInfo: TokenIconInfo
        let destinationAmountText: String
        let state: State
        let action: (String) -> Void

        static func == (lhs: Info, rhs: Info) -> Bool {
            return lhs.id == rhs.id && lhs.state == rhs.state
        }
    }

    enum State: Equatable {
        case inProgress
        case warning
        case error
    }
}

struct PendingExpressTransactionView_Previews: PreviewProvider {
    static let iconInfoBuilder = TokenIconInfoBuilder()
    static var previews: some View {
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            VStack {
                PendingExpressTransactionView(info: .init(
                    id: UUID().uuidString,
                    title: Localization.expressExchangeBy("ChangeNow"),
                    sourceIconInfo: iconInfoBuilder.build(from: .blockchain(.init(.polygon(testnet: false), derivationPath: nil)), isCustom: false),
                    sourceAmountText: "10 BTC",
                    destinationIconInfo: iconInfoBuilder.build(
                        from: .token(.shibaInuMock, .init(.arbitrum(testnet: false), derivationPath: nil)),
                        isCustom: false
                    ),
                    destinationAmountText: "SHIB",
                    state: .inProgress,
                    action: { _ in }
                ))

                PendingExpressTransactionView(info: .init(
                    id: UUID().uuidString,
                    title: Localization.expressExchangeBy("1inch"),
                    sourceIconInfo: iconInfoBuilder.build(
                        from: .token(.inverseBTCBlaBlaBlaMock, .init(.ethereum(testnet: false), derivationPath: nil)),
                        isCustom: true
                    ),
                    sourceAmountText: "10 BTCblabla",
                    destinationIconInfo: iconInfoBuilder.build(
                        from: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
                        isCustom: true
                    ),
                    destinationAmountText: "ETH",
                    state: .warning,
                    action: { _ in }
                ))

                PendingExpressTransactionView(info: .init(
                    id: UUID().uuidString,
                    title: Localization.expressExchangeBy("ChangeNow"),
                    sourceIconInfo: iconInfoBuilder.build(
                        from: .blockchain(.init(.bitcoin(testnet: false), derivationPath: nil)),
                        isCustom: false
                    ),
                    sourceAmountText: "10 BTC",
                    destinationIconInfo: iconInfoBuilder.build(
                        from: .blockchain(.init(.cardano(extended: false), derivationPath: nil)),
                        isCustom: false
                    ),
                    destinationAmountText: "ADA",
                    state: .error,
                    action: { _ in }
                ))
            }
        }
    }
}
