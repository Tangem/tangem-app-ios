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
        VStack(spacing: 16) {
            headerView

            content

            buttons
        }
        .padding(.top, 16)
        .padding(.bottom, 4)
        .background(Colors.Background.secondary)
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            Text("swapping_permission_header".localized)
                .style(Fonts.Bold.callout, color: Colors.Text.primary1)

            Text("swapping_permission_subheader".localized(viewModel.smartContractNetworkName))
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
                title: "swapping_permission_buttons_approve".localized,
                icon: .trailing(Assets.tangemIcon),
                action: viewModel.approveDidTapped)

            MainButton(
                title: "common_cancel".localized,
                style: .secondary,
                action: viewModel.cancelDidTapped
            )
        }
        .padding(.horizontal, 16)
    }
}

struct SwappingPermissionView_Preview: PreviewProvider {
    static let viewModel = SwappingPermissionViewModel(
        inputModel: SwappingPermissionViewModel.InputModel(
            smartContractNetworkName: "DAI",
            amount: 1000,
            yourWalletAddress: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
            spenderWalletAddress: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
            fee: 2.14
        ),
        coordinator: SwappingCoordinator()
    )

    static var previews: some View {
        SwappingPermissionView(viewModel: viewModel)
    }
}
