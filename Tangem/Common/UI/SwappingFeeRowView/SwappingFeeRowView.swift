//
//  SwappingFeeRowView.swift
//  Tangem
//
//  Created by Sergey Balashov on 30.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SwappingFeeRowView: View {
    private let viewModel: SwappingFeeRowViewModel
    @Binding private var isDisclaimerOpened: Bool

    init(viewModel: SwappingFeeRowViewModel) {
        self.viewModel = viewModel
        _isDisclaimerOpened = viewModel.isDisclaimerOpened()
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(Localization.sendNetworkFeeTitle)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()

            content
        }
        .lineLimit(1)
        .padding(.vertical, 14)
        .background(Colors.Background.primary)
        .contentShape(Rectangle())
        .onTapGesture {
            isDisclaimerOpened.toggle()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case .loading:
            SkeletonView()
                .frame(width: 100, height: 11)
                .cornerRadiusContinuous(3)

        case .fee:
            HStack(spacing: 4) {
                Text(viewModel.state.formattedFee ?? "")
                    .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                Assets.chevronDownMini.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)
                    .rotationEffect(.degrees(isDisclaimerOpened ? -180 : 0))
            }
        }
    }
}

struct SwappingFeeRowView_Previews: PreviewProvider {
    struct ContentView: View {
        @State private var isDisclaimerOpened: Bool = false

        var body: some View {
            ZStack {
                Colors.Background.secondary

                GroupedSection([
                    SwappingFeeRowViewModel(
                        state: .fee(fee: "0.0000000000155", symbol: "MATIC", fiat: "$0.14"), isDisclaimerOpened: { $isDisclaimerOpened }
                    ), SwappingFeeRowViewModel(
                        state: .loading, isDisclaimerOpened: { $isDisclaimerOpened }
                    ),
                ]) {
                    SwappingFeeRowView(viewModel: $0)
                }
                .padding()
            }
        }
    }

    static var previews: some View {
        ContentView()
    }
}
