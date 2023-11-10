//
//  ExpressProvidersBottomSheetView.swift
//  Tangem
//
//  Created by Sergey Balashov on 02.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressProvidersBottomSheetView: View {
    @ObservedObject private var viewModel: ExpressProvidersBottomSheetViewModel

    init(viewModel: ExpressProvidersBottomSheetViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(
                title: Localization.expressChooseProvidersTitle,
                subtitle: Localization.expressChooseProvidersSubtitle
            )

            GroupedSection(viewModel.providerViewModels) {
                ProviderRowView(viewModel: $0)
            }
            .interItemSpacing(14)
            .interSectionPadding(12)
            .verticalPadding(16)
        }
        .padding(.horizontal, 16)
    }
}

struct ExpressProvidersBottomSheetView_Preview: PreviewProvider {
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
                        ExpressProvidersBottomSheetView(viewModel: $0)
                    }
            }
        }
    }

    class BottomSheetCoordinator: ObservableObject, ExpressProvidersBottomSheetRoutable {
        @Published var item: ExpressProvidersBottomSheetViewModel?

        func toggleItem() {
            if item == nil {
                item = ExpressProvidersBottomSheetViewModel(coordinator: self)
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
