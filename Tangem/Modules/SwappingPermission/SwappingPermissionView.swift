//
//  SwappingPermissionView.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SwappingPermissionView: View {
    @ObservedObject private var viewModel: SwappingPermissionViewModel

    init(viewModel: SwappingPermissionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            mainContent

            infoButton
        }
        .background(Colors.Background.secondary)
        .alert(item: $viewModel.errorAlert, content: { $0.alert })
    }

    private var infoButton: some View {
        Button(action: {
            viewModel.didTapInfoButton()
        }) {
            Assets.infoIconMini.image
                .padding(.trailing, 16)
        }
    }

    private var mainContent: some View {
        VStack(spacing: 16) {
            headerView

            content

            buttons
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            Text(Localization.swappingPermissionHeader)
                .style(Fonts.Bold.callout, color: Colors.Text.primary1)

            Text(Localization.swappingPermissionSubheader(viewModel.tokenSymbol))
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                .padding(.horizontal, 50)
                .multilineTextAlignment(.center)
        }
    }

    private var content: some View {
        GroupedSection(viewModel.contentRowViewModels) {
            DefaultRowView(viewModel: $0)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 16)
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            MainButton(
                title: Localization.swappingPermissionButtonsApprove,
                icon: .trailing(Assets.tangemIcon),
                action: viewModel.didTapApprove
            )

            MainButton(
                title: Localization.commonCancel,
                style: .secondary,
                action: viewModel.didTapCancel
            )
        }
        /// This fixed text font in the cancel button, it shrink with no reason
        .minimumScaleFactor(1)
        .padding(.horizontal, 16)
    }
}

struct SwappingPermissionView_Preview: PreviewProvider {
    static let viewModel = SwappingPermissionViewModel(
        inputModel: SwappingPermissionInputModel(fiatFee: 1.45, transactionData: .mock),
        transactionSender: TransactionSenderMock(),
        coordinator: SwappingCoordinator()
    )

    static var previews: some View {
        SwappingPermissionView(viewModel: viewModel)
    }
}
