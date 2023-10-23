//
//  ResetToFactoryView.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ResetToFactoryView: View {
    @ObservedObject private var viewModel: ResetToFactoryViewModel

    init(viewModel: ResetToFactoryViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: .zero) {
            Spacer(minLength: 0)

            headerView

            Spacer(minLength: 0)

            warningPointsView

            Spacer(minLength: 24).frame(maxHeight: 48)

            actionButton
                .layoutPriority(1)
        }
        .padding(.bottom, max(10, UIApplication.safeAreaInsets.bottom))
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarTitle(Text(Localization.cardSettingsResetCardToFactory), displayMode: .inline)
        .actionSheet(item: $viewModel.actionSheet) { $0.sheet }
        .alert(item: $viewModel.alert) { $0.alert }
    }

    private var headerView: some View {
        VStack(alignment: .center, spacing: 28) {
            Assets.attentionRed.image

            mainInformationView
        }
    }

    private var mainInformationView: some View {
        VStack(alignment: .center, spacing: 14) {
            Text(Localization.commonAttention)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text(viewModel.message)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 46)
    }

    private var warningPointsView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            accessToCardWarningMessage

            if viewModel.hasBackupCards {
                Spacer(minLength: 16).frame(maxHeight: 24)

                recoverBackupWarningMessage
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    private var accessToCardWarningMessage: some View {
        Button(action: { viewModel.accessToCardWarningSelected.toggle() }) {
            HStack(spacing: 16) {
                SelectableIcon(isSelected: $viewModel.accessToCardWarningSelected)

                Text(Localization.resetCardToFactoryCondition1)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var recoverBackupWarningMessage: some View {
        Button(action: { viewModel.accessCodeRecoveryWarningSelected.toggle() }) {
            HStack(spacing: 16) {
                SelectableIcon(isSelected: $viewModel.accessCodeRecoveryWarningSelected)

                Text(Localization.resetCardToFactoryCondition2)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var actionButton: some View {
        MainButton(
            title: Localization.resetCardToFactoryButtonTitle,
            icon: .trailing(Assets.tangemIcon),
            isDisabled: !viewModel.actionButtonIsEnabled,
            action: viewModel.didTapMainButton
        )
        .padding(.horizontal, 16)
    }
}

private extension ResetToFactoryView {
    struct SelectableIcon: View {
        @Binding var isSelected: Bool

        var body: some View {
            ZStack(alignment: .center) {
                if isSelected {
                    Circle()
                        .fill(Colors.Icon.primary1)
                        .frame(width: 22, height: 22)
                } else {
                    Circle()
                        .strokeBorder(Colors.Icon.inactive, lineWidth: 2)
                        .frame(width: 22, height: 22)
                }

                if isSelected {
                    Assets.check.image
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 10, height: 10)
                        .foregroundColor(Colors.Icon.primary2)
                }
            }
            .animation(.none, value: isSelected)
        }
    }
}

struct ResetToFactoryView_Previews: PreviewProvider {
    static let viewModel = ResetToFactoryViewModel(
        input: .init(
            cardInteractor: CardResettableMock(),
            hasBackupCards: false,
            userWalletId: UserWalletId(value: Data())
        ),
        coordinator: CardSettingsCoordinator()
    )

    static var previews: some View {
        NavigationView {
            ResetToFactoryView(viewModel: viewModel)
        }
    }
}
