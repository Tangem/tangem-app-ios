//
//  ExpressSuccessSentView.swift
//  Tangem
//
//  Created by Sergey Balashov on 20.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressSuccessSentView: View {
    @ObservedObject private var viewModel: ExpressSuccessSentViewModel

    init(viewModel: ExpressSuccessSentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .top) {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            VStack(spacing: .zero) {
                titleView

                VStack(spacing: 14) {
                    GroupedSection(viewModel.sourceData) {
                        AmountSummaryView(data: $0)
                    }
                    .interSectionPadding(12)
                    .verticalPadding(0)

                    GroupedSection(viewModel.destinationData) {
                        AmountSummaryView(data: $0)
                    }
                    .interSectionPadding(12)
                    .verticalPadding(0)

                    GroupedSection(viewModel.provider) {
                        ProviderRowView(viewModel: $0)
                    }
                    .interSectionPadding(12)
                    .verticalPadding(0)

                    GroupedSection(viewModel.expressFee) {
                        ExpressFeeRowView(viewModel: $0)
                    }
                    .interSectionPadding(12)
                    .verticalPadding(0)
                }
            }
            .padding(.horizontal, 14)

            buttonsView
        }
    }

    private var titleView: some View {
        VStack(spacing: 18) {
            Assets.swapInProcessIcon.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.inactive)

            VStack(spacing: 4) {
                Text(Localization.swappingSuccessViewTitle)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                Text(viewModel.dateFormatted)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
        .padding(.vertical, 24)
    }

    private var buttonsView: some View {
        VStack(spacing: .zero) {
            Spacer()

            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    MainButton(
                        title: Localization.commonExplore,
                        icon: .leading(Assets.compassExplore),
                        style: .secondary,
                        action: viewModel.openExplore
                    )

                    if viewModel.isStatusButtonVisible {
                        MainButton(
                            title: Localization.expressCexStatusButtonTitle,
                            icon: .leading(Assets.share),
                            style: .secondary,
                            action: viewModel.openCEXStatus
                        )
                    }
                }

                MainButton(
                    title: Localization.commonClose,
                    style: .primary,
                    action: viewModel.closeView
                )
            }
        }
        .padding(.horizontal, 16)
    }
}

/*
 // TODO: https://tangem.atlassian.net/browse/IOS-5212
 struct ExpressSuccessSentView_Preview: PreviewProvider {
     static let viewModel = ExpressSuccessSentViewModel(
         input: .init(),
         coordinator: ExpressSuccessSentRoutableMock()
     )

     static var previews: some View {
         NavHolder()
             .sheet(item: .constant(viewModel)) {
                 ExpressSuccessSentView(viewModel: $0)
             }
     }
 }

 class ExpressSuccessSentRoutableMock: ExpressSuccessSentRoutable {}
 */
