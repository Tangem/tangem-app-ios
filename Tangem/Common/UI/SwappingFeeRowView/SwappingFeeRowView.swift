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
    @State private var isShowingDisclaimer: Bool

    init(viewModel: SwappingFeeRowViewModel) {
        self.viewModel = viewModel
        isShowingDisclaimer = viewModel.isShowingDisclaimer.value
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
        .connect(state: $isShowingDisclaimer, to: viewModel.isShowingDisclaimer)
        .onTapGesture {
            isShowingDisclaimer.toggle()
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

        case .policy(let title, let fiat):
            HStack(spacing: 4) {
                HStack(spacing: 0) {
                    Text(title)
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                    Text(" (\(fiat))")
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
                }

                Assets.chevronDownMini.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)
                    .rotationEffect(.degrees(isShowingDisclaimer ? -180 : 0))
            }
        }
    }
}

struct SwappingFeeRowView_Previews: PreviewProvider {
    struct ContentView: View {
        @State private var isShowingDisclaimer: Bool = false

        var body: some View {
            ZStack {
                Colors.Background.secondary

                GroupedSection([
                    SwappingFeeRowViewModel(
                        state: .policy(title: "Normal", fiat: "0.0000000000155 MATIC ($0.14)"),
                        isShowingDisclaimer: $isShowingDisclaimer.asBindingValue
                    ),
                    SwappingFeeRowViewModel(
                        state: .loading,
                        isShowingDisclaimer: $isShowingDisclaimer.asBindingValue
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
