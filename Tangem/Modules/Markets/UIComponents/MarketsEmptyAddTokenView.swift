//
//  MarketsEmptyAddTokenView.swift
//  Tangem
//
//  Created by skibinalexander on 11.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsEmptyAddTokenView: View {
    // MARK: - Properties

    private(set) var didTapAction: (() -> Void)?

    // MARK: - UI

    var body: some View {
        VStack(spacing: 12) {
            headerView

            buttonView
        }
        .padding(14)
        .background(Colors.Background.secondary)
        .cornerRadiusContinuous(14)
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("My portfolio")
                    .lineLimit(1)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Text("To start buying, exchanging or receiving this asset, add this token to at least 1 network")
                    .lineLimit(2)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }

            Spacer()
        }
    }

    private var buttonView: some View {
        VStack(alignment: .leading) {
            MainButton(title: "Add to portfolio ") {
                didTapAction?()
            }
        }
    }
}

#Preview {
    MarketsEmptyAddTokenView()
}
