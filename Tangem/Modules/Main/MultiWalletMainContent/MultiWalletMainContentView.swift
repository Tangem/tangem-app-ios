//
//  MultiWalletMainContentView.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MultiWalletMainContentView: View {
    @ObservedObject var viewModel: MultiWalletMainContentViewModel

    var body: some View {
        VStack(spacing: 14) {
            if let settings = viewModel.missingDerivationNotificationSettings {
                NotificationView(settings: settings, buttons: [
                    .init(
                        action: viewModel.didTapNotificationButton(with:action:),
                        actionType: .generateAddresses
                    ),
                ])
                .setButtonsLoadingState(to: viewModel.isScannerBusy)
                .transition(.scaleOpacity)
            }

            if let settings = viewModel.missingBackupNotificationSettings {
                NotificationView(settings: settings, buttons: [
                    .init(
                        action: viewModel.didTapNotificationButton(with:action:),
                        actionType: .backupCard
                    ),
                ])
            }

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .transition(.scaleOpacity)
            }

            ForEach(viewModel.tokensNotificationInputs) { input in
                NotificationView(input: input)
                    .transition(.scaleOpacity)
            }

            tokensContent

            if viewModel.isOrganizeTokensVisible {
                FixedSizeButtonWithLeadingIcon(
                    title: Localization.organizeTokensTitle,
                    icon: Assets.OrganizeTokens.filterIcon.image,
                    action: viewModel.onOpenOrganizeTokensButtonTap
                )
                .infinityFrame(axis: .horizontal)
            }
        }
        .animation(.default, value: viewModel.missingDerivationNotificationSettings)
        .animation(.default, value: viewModel.notificationInputs)
        .animation(.default, value: viewModel.tokensNotificationInputs)
        .padding(.horizontal, 16)
        .background(
            Color.clear
                .alert(item: $viewModel.error, content: { $0.alert })
        )
    }

    private var tokensContent: some View {
        Group {
            if viewModel.isLoadingTokenList {
                TokenListLoadingPlaceholderView()
            } else {
                if viewModel.sections.isEmpty {
                    emptyList
                } else {
                    tokensList
                }
            }
        }
        .cornerRadiusContinuous(Constants.cornerRadius)
    }

    private var emptyList: some View {
        VStack(spacing: 16) {
            Assets.emptyTokenList.image
                .foregroundColor(Colors.Icon.inactive)

            Text(Localization.mainEmptyTokensListMessage)
                .multilineTextAlignment(.center)
                .style(
                    Fonts.Regular.caption1,
                    color: Colors.Text.tertiary
                )
        }
        .padding(.top, 96)
        .padding(.horizontal, 48)
    }

    private var tokensList: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.sections) { section in
                TokenSectionView(title: section.model.title)
                    .background(Colors.Background.primary)

                ForEach(section.items) { item in
                    TokenItemView(viewModel: item)
                        .background(Colors.Background.primary)
                        .onTapGesture(perform: item.tapAction)
                        .highlightable(color: Colors.Button.primary.opacity(0.03))
                        // `previewContentShape` must be called just before `contextMenu` call, otherwise visual glitches may occur
                        .previewContentShape(cornerRadius: Constants.cornerRadius)
                        .contextMenu {
                            ForEach(viewModel.contextActions(for: item), id: \.self) { menuAction in
                                contextMenuButton(for: menuAction, tokenItem: item)
                            }
                        }
                }
            }
        }
        .background(Colors.Background.primary)
    }

    @ViewBuilder
    private func contextMenuButton(for actionType: TokenActionType, tokenItem: TokenItemViewModel) -> some View {
        let action = { viewModel.didTapContextAction(actionType, for: tokenItem) }
        if #available(iOS 15, *), actionType.isDestructive {
            Button(
                role: .destructive,
                action: action,
                label: {
                    labelForContextButton(with: actionType)
                }
            )
        } else {
            Button(action: action, label: {
                labelForContextButton(with: actionType)
            })
        }
    }

    private func labelForContextButton(with action: TokenActionType) -> some View {
        HStack {
            Text(action.title)
            action.icon.image
                .renderingMode(.template)
        }
    }
}

struct MultiWalletContentView_Preview: PreviewProvider {
    static let viewModel: MultiWalletMainContentViewModel = {
        let repo = FakeUserWalletRepository()
        let mainCoordinator = MainCoordinator()
        let userWalletModel = repo.models.first!

        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository()
        InjectedValues[\.tangemApiService] = FakeTangemApiService()

        let optionsManager = OrganizeTokensOptionsManagerStub()
        let tokenSectionsAdapter = TokenSectionsAdapter(
            userTokenListManager: userWalletModel.userTokenListManager,
            optionsProviding: optionsManager,
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )

        return MultiWalletMainContentViewModel(
            userWalletModel: userWalletModel,
            userWalletNotificationManager: FakeUserWalletNotificationManager(),
            tokensNotificationManager: FakeUserWalletNotificationManager(),
            coordinator: mainCoordinator,
            tokenSectionsAdapter: tokenSectionsAdapter,
            tokenRouter: SingleTokenRoutableMock()
        )
    }()

    static var previews: some View {
        ScrollView {
            MultiWalletMainContentView(viewModel: viewModel)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Constants

private extension MultiWalletMainContentView {
    enum Constants {
        static let cornerRadius = 14.0
    }
}
