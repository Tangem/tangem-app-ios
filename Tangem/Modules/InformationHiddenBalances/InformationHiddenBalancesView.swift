//
//  InformationHiddenBalancesView.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct InformationHiddenBalancesView: View {
    @ObservedObject private var viewModel: InformationHiddenBalancesViewModel

    init(viewModel: InformationHiddenBalancesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 30) {
            Assets.crossedEyeIcon.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.primary1)

            textView

            buttonView
        }
        .padding(.top, 46)
        .padding(.horizontal, 16)
    }

    private var textView: some View {
        VStack(spacing: 10) {
            Text(Localization.balanceHiddenTitle)
                .style(Fonts.Regular.title1, color: Colors.Text.primary1)

            Text(Localization.balanceHiddenDescription)
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }

    private var buttonView: some View {
        VStack(spacing: 10) {
            MainButton(title: Localization.balanceHiddenGotItButton, style: .primary) {
                viewModel.userDidRequestCloseView()
            }

            MainButton(title: Localization.balanceHiddenDoNotShowButton, style: .secondary) {
                viewModel.userDidRequestDoNotShowAgain()
            }
        }
        .padding(.vertical, 6)
    }
}

struct InformationHiddenBalancesView_Preview: PreviewProvider {
    struct StatableContainer: View {
        @ObservedObject private var coordinator = BottomSheetCoordinator()

        var body: some View {
            ZStack {
                Colors.Background.primary
                    .edgesIgnoringSafeArea(.all)

                Button("Bottom sheet isShowing \((coordinator.item != nil).description)") {
                    coordinator.toggleItem()
                }
                .font(Fonts.Bold.body)
                .offset(y: -200)

                NavHolder()
                    .bottomSheet(item: $coordinator.item, backgroundColor: Colors.Background.tertiary) {
                        InformationHiddenBalancesView(viewModel: $0)
                    }
            }
        }
    }

    class BottomSheetCoordinator: ObservableObject, InformationHiddenBalancesRoutable {
        @Published var item: InformationHiddenBalancesViewModel?

        func toggleItem() {
            if item == nil {
                item = InformationHiddenBalancesViewModel(coordinator: self)
            } else {
                item = nil
            }
        }

        func hiddenBalancesSheetDidRequestClose() {
            item = nil
        }

        func hiddenBalancesSheetDidRequestDoNotShowAgain() {
            item = nil
        }
    }

    static var previews: some View {
        StatableContainer()
            .preferredColorScheme(.light)

        StatableContainer()
            .preferredColorScheme(.dark)
    }
}
