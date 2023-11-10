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
            .horizontalPadding(14)
            .verticalPadding(0)
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
            if item == nil {
                item = ExpressFeeBottomSheetViewModel(coordinator: self)
            } else {
                item = nil
            }
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
