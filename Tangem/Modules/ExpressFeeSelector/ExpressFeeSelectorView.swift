//
//  ExpressFeeSelectorView.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressFeeSelectorView: View {
    @ObservedObject private var viewModel: ExpressFeeSelectorViewModel

    init(viewModel: ExpressFeeSelectorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(title: Localization.commonFeeSelectorTitle)

            GroupedSection(viewModel.feeRowViewModels) {
                FeeRowView(viewModel: $0)
            } footer: {
                Text(footerAttributedString)
            }
            .interItemSpacing(0)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
        }
    }

    private var footerAttributedString: AttributedString {
        let readMore = Localization.commonReadMore
        var attributed = AttributedString(Localization.commonFeeSelectorFooter(readMore))
        attributed.foregroundColor = Colors.Text.tertiary
        attributed.font = Fonts.Regular.caption1

        if let range = attributed.range(of: readMore) {
            attributed[range].foregroundColor = Colors.Text.accent
            attributed[range].link = AppConstants.feeExplanationTangemBlogURL
        }

        return attributed
    }
}

struct ExpressFeeSelectorView_Preview: PreviewProvider {
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
                        ExpressFeeSelectorView(viewModel: $0)
                    }
            }
        }
    }

    class BottomSheetCoordinator: ObservableObject, ExpressFeeSelectorRoutable {
        @Published var item: ExpressFeeSelectorViewModel?

        func toggleItem() {
            if item == nil {
                item = ExpressModulesFactoryMock().makeExpressFeeSelectorViewModel(coordinator: self)
            } else {
                item = nil
            }
        }

        func closeExpressFeeSelector() {
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
