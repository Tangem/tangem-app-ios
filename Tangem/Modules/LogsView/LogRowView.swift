//
//  LogRowView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 22.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLogger

struct LogRowViewData: Identifiable {
    let id: UUID
    let log: OSLogEntry

    init(id: UUID = .init(), log: OSLogEntry) {
        self.id = id
        self.log = log
    }
}

struct LogRowView: View {
    let data: LogRowViewData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.log.message)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

            HStack(spacing: 4) {
                Group {
                    Text(data.log.category)

                    Text(AppConstants.dotSign)

                    Text(data.log.level)
                }.style(Fonts.Bold.caption1, color: Colors.Text.tertiary)

                Spacer()

                Group {
                    Text(data.log.date)

                    Text(data.log.time)
                }
                .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)
            }
            .lineLimit(1)
        }
        .padding(.vertical, 12)
        .background(background)
    }

    var background: Color {
        switch Logger.Level(rawValue: data.log.level.lowercased()) {
        case .error: Color.red.opacity(0.2)
        case .warning: Color.yellow.opacity(0.2)
        default: Color.clear
        }
    }
}
