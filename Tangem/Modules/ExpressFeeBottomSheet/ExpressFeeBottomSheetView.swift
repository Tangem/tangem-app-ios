//
//  ExpressFeeBottomSheetView.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressFeeBottomSheetView: View {
    @ObservedObject private var viewModel: ExpressFeeBottomSheetViewModel

    init(viewModel: ExpressFeeBottomSheetViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(title: Localization.commonFeeSelectorTitle)

            GroupedSection(viewModel.feeRowViewModels) {
                FeeRowView(viewModel: $0)
            } footer: {
                DefaultFooterView(Localization.commonFeeSelectorFooter)
            }
            .interItemSpacing(0)
            .verticalPadding(10)
            .horizontalPadding(14)
            .separatorStyle(.minimum)
            .padding(.horizontal, 14)
        }
    }
}

struct ExpressFeeBottomSheetView_Preview: PreviewProvider {
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
                    .bottomSheet(item: $coordinator.item) {
                        ExpressFeeBottomSheetView(viewModel: $0)
                    }
            }
        }
    }

    class BottomSheetCoordinator: ObservableObject, ExpressFeeBottomSheetRoutable {
        @Published var item: ExpressFeeBottomSheetViewModel?

        func toggleItem() {
            // TODO: https://tangem.atlassian.net/browse/IOS-5212
        }

        func closeExpressFeeBottomSheet() {
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
