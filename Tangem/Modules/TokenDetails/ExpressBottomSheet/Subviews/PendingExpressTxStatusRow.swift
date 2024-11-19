//
//  PendingExpressTxStatusRow.swift
//  Tangem
//
//  Created by Andrew Son on 05/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct PendingExpressTxStatusRow: View {
    let isFirstRow: Bool
    let info: StatusRowData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !isFirstRow {
                Assets.verticalLine.image
                    .foregroundColor(Colors.Field.focused)
            }

            HStack(spacing: 12) {
                ZStack {
                    Assets.circleOutline20.image
                        .foregroundColor(info.state.circleColor)
                        .opacity(info.state.circleOpacity)

                    info.state.foregroundIcon
                }

                Text(info.title)
                    .style(Fonts.Regular.footnote, color: info.state.textColor)

                Spacer()
            }
        }
    }
}

extension PendingExpressTxStatusRow {
    struct StatusRowData: Identifiable, Hashable, Equatable {
        let title: String
        let state: State

        var id: Int { hashValue }
    }

    enum State: Hashable {
        case empty
        case loader
        case checkmark
        case cross(passed: Bool)
        case exclamationMark

        var foregroundIcon: some View {
            Group {
                switch self {
                case .empty: EmptyView()
                case .loader:
                    ProgressView()
                        .progressViewStyle(.circular)
                case .checkmark:
                    Assets.checkmark20.image
                case .cross:
                    Assets.cross20.image
                case .exclamationMark:
                    Assets.exclamationMark20.image
                }
            }
            .foregroundColor(iconColor)
            .frame(size: .init(bothDimensions: 20))
        }

        var circleColor: Color {
            switch self {
            case .empty, .checkmark: return Colors.Field.focused
            case .loader: return Color.clear
            case .cross(let passed):
                return passed ? Colors.Field.focused : Colors.Icon.warning
            case .exclamationMark: return Colors.Icon.attention
            }
        }

        var iconColor: Color {
            switch self {
            case .empty: return Color.clear
            case .loader, .checkmark: return Colors.Text.primary1
            case .cross(let passed):
                return passed ? Colors.Text.primary1 : Colors.Icon.warning
            case .exclamationMark: return Colors.Icon.attention
            }
        }

        var textColor: Color {
            switch self {
            case .checkmark, .loader: return Colors.Text.primary1
            case .empty: return Colors.Text.disabled
            case .cross(let passed):
                return passed ? Colors.Text.primary1 : Colors.Text.warning
            case .exclamationMark: return Colors.Text.attention
            }
        }

        var circleOpacity: Double {
            switch self {
            case .empty, .loader, .checkmark: return 1.0
            case .exclamationMark: return 0.4
            case .cross(let passed):
                return passed ? 1.0 : 0.4
            }
        }
    }
}

struct PendingExpressTxStatusRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            PendingExpressTxStatusRow(isFirstRow: true, info: .init(title: "Deposit received", state: .checkmark))
            PendingExpressTxStatusRow(isFirstRow: false, info: .init(title: "Exchanging...", state: .loader))
            PendingExpressTxStatusRow(isFirstRow: false, info: .init(title: "Failed", state: .cross(passed: false)))
            PendingExpressTxStatusRow(isFirstRow: false, info: .init(title: "Failed", state: .cross(passed: true)))
            PendingExpressTxStatusRow(isFirstRow: false, info: .init(title: "Canceled", state: .cross(passed: false)))
            PendingExpressTxStatusRow(isFirstRow: false, info: .init(title: "Refunded", state: .empty))
            PendingExpressTxStatusRow(isFirstRow: false, info: .init(title: "Refunded", state: .checkmark))
            PendingExpressTxStatusRow(isFirstRow: false, info: .init(title: "Verification required", state: .exclamationMark))
        }
    }
}
