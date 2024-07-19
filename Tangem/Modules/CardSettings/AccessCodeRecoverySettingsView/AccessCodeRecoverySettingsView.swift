//
//  AccessCodeRecoverySettingsView.swift
//  Tangem
//
//  Created by Andrew Son on 06/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct AccessCodeRecoverySettingsView: View {
    @ObservedObject var viewModel: AccessCodeRecoverySettingsViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            GroupedScrollView {
                GroupedSection(viewModel.viewModels) {
                    DefaultSelectableRowView(data: $0, selection: $viewModel.isUserCodeRecoveryAllowed)
                }
            }
            .disabled(viewModel.isLoading)

            saveChangesButton
        }
        .alert(item: $viewModel.errorAlert, content: { $0.alert })
        .navigationBarTitle(Text(Localization.cardSettingsAccessCodeRecoveryTitle), displayMode: .inline)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private var saveChangesButton: some View {
        MainButton(
            title: Localization.commonSaveChanges,
            icon: .trailing(Assets.tangemIcon),
            isLoading: viewModel.isLoading,
            isDisabled: viewModel.actionButtonDisabled,
            action: viewModel.actionButtonDidTap
        )
        .padding(16)
    }
}

struct AccessCodeRecoverySettingsView_Previews: PreviewProvider {
    private static let viewModel = AccessCodeRecoverySettingsViewModel(with: UserCodeRecoveringMock())
    static var previews: some View {
        AccessCodeRecoverySettingsView(viewModel: viewModel)
    }
}
