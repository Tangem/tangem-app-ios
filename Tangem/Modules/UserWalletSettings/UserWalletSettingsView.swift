//
//  UserWalletSettingsView.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct UserWalletSettingsView: View {
    @ObservedObject private var viewModel: UserWalletSettingsViewModel

    init(viewModel: UserWalletSettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GroupedScrollView(alignment: .leading, spacing: 24) {
            nameSection

            backupSection

            commonSection

            forgetSection
        }
        .interContentPadding(8)
        .background(Colors.Background.secondary.ignoresSafeArea())
        .navigationTitle(Localization.walletSettingsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert) { $0.alert }
        .actionSheet(item: $viewModel.actionSheet) { $0.sheet }
        .scrollDismissesKeyboardCompat(.interactively)
        .onAppear(perform: viewModel.onAppear)
    }

    private var nameSection: some View {
        DefaultTextFieldRowView(
            title: Localization.settingsWalletNameTitle,
            text: .constant(viewModel.name),
            isReadonly: true
        )
        .defaultRoundedBackground()
        .onTapGesture(perform: viewModel.onTapNameField)
    }

    private var backupSection: some View {
        GroupedSection(viewModel.backupViewModel) {
            DefaultRowView(viewModel: $0)
        }
    }

    private var commonSection: some View {
        GroupedSection(viewModel.commonSectionModels) {
            DefaultRowView(viewModel: $0)
        }
    }

    private var forgetSection: some View {
        GroupedSection(viewModel.forgetViewModel) {
            DefaultRowView(viewModel: $0)
                .appearance(.destructiveButton)
        } footer: {
            DefaultFooterView(Localization.settingsForgetWalletFooter)
        }
    }
}

struct UserWalletSettingsView_Preview: PreviewProvider {
    static let viewModel = UserWalletSettingsViewModel(
        userWalletModel: UserWalletModelMock(),
        coordinator: UserWalletSettingsCoordinator()
    )

    static var previews: some View {
        UserWalletSettingsView(viewModel: viewModel)
    }
}
