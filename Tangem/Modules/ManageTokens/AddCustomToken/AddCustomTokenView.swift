//
//  AddCustomTokenView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 22.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddCustomTokenView: View {
    @ObservedObject private var viewModel: AddCustomTokenViewModel

    @FocusState private var isFocusedNameField: Bool
    @FocusState private var isFocusedSymbolField: Bool
    @FocusState private var isFocusedDecimalsField: Bool

    init(viewModel: AddCustomTokenViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(Localization.customTokenSubtitle)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 38)
                    .padding(.bottom, 22)

                VStack(spacing: 14) {
                    if viewModel.canSelectWallet {
                        Button(action: viewModel.didTapWalletSelector) {
                            ItemSelectorRow(title: Localization.manageTokensNetworkSelectorWallet, selectedItem: viewModel.selectedWalletName)
                        }
                        .background(Colors.Background.action)
                        .cornerRadiusContinuous(14)
                    }

                    Button(action: viewModel.didTapNetworkSelector) {
                        ItemSelectorRow(title: Localization.customTokenNetworkInputTitle, selectedItem: viewModel.selectedBlockchainName)
                    }
                    .background(Colors.Background.action)
                    .cornerRadiusContinuous(14)

                    if viewModel.selectedBlockchainSupportsTokens {
                        VStack(spacing: 0) {
                            TextInputWithTitle(title: Localization.customTokenContractAddressInputTitle, placeholder: "0x0000000000000000000000000000000000000000", text: $viewModel.contractAddress, keyboardType: .default, isEnabled: true, isLoading: false, error: viewModel.contractAddressError)

                            separator

                            TextInputWithTitle(
                                title: Localization.customTokenNameInputTitle,
                                placeholder: Localization.customTokenNameInputPlaceholder,
                                text: $viewModel.name,
                                keyboardType: .default,
                                isEnabled: true,
                                isLoading: viewModel.isLoading
                            )
                            .focused($isFocusedNameField)
                            .onChange(of: isFocusedNameField) { isFocused in
                                guard !isFocused else { return }
                                viewModel.onChangeFocusable(field: .name)
                            }

                            separator

                            TextInputWithTitle(
                                title: Localization.customTokenTokenSymbolInputTitle,
                                placeholder: Localization.customTokenTokenSymbolInputPlaceholder,
                                text: $viewModel.symbol,
                                keyboardType: .default,
                                isEnabled: true,
                                isLoading: viewModel.isLoading
                            )
                            .focused($isFocusedSymbolField)
                            .onChange(of: isFocusedSymbolField) { isFocused in
                                guard !isFocused else { return }
                                viewModel.onChangeFocusable(field: .symbol)
                            }

                            separator

                            TextInputWithTitle(
                                title: Localization.customTokenDecimalsInputTitle,
                                placeholder: "0",
                                text: $viewModel.decimals,
                                keyboardType: .numberPad,
                                isEnabled: true,
                                isLoading: viewModel.isLoading,
                                error: viewModel.decimalsError
                            )
                            .focused($isFocusedDecimalsField)
                            .onChange(of: isFocusedDecimalsField) { isFocused in
                                guard !isFocused else { return }
                                viewModel.onChangeFocusable(field: .decimals)
                            }
                        }
                        .background(Colors.Background.action)
                        .cornerRadiusContinuous(14)
                    }

                    if viewModel.showDerivationPaths {
                        Button(action: viewModel.didTapDerivationSelector) {
                            ItemSelectorRow(title: Localization.customTokenDerivationPath, selectedItem: viewModel.selectedDerivationOption?.name ?? "")
                        }
                        .background(Colors.Background.action)
                        .cornerRadiusContinuous(14)
                    }

                    if let notificationInput = viewModel.notificationInput {
                        NotificationView(input: notificationInput)
                    }

                    MainButton(
                        title: Localization.customTokenAddToken,
                        isLoading: viewModel.isLoading,
                        isDisabled: viewModel.addButtonDisabled,
                        action: viewModel.createToken
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        .onAppear(perform: viewModel.onAppear)
        .alert(item: $viewModel.error, content: { $0.alert })
        .navigationBarTitle(Text(Localization.addCustomTokenTitle), displayMode: .inline)
    }

    private var separator: some View {
        Separator(height: .minimal, color: Colors.Stroke.primary)
            .padding(.leading, 16)
    }
}

// MARK: - Item selector

private struct ItemSelectorRow: View {
    let title: String
    let selectedItem: String?

    var body: some View {
        HStack(spacing: 16) {
            Text(title)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let selectedItem {
                Text(selectedItem)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
            }

            Assets.chevron.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.informative)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Text input

private struct TextInputWithTitle: View {
    let title: String
    let placeholder: String
    let text: Binding<String>
    let keyboardType: UIKeyboardType
    let isEnabled: Bool
    let isLoading: Bool
    var error: Error?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let error {
                Text(error.localizedDescription)
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
            } else {
                Text(title)
                    .style(Fonts.Regular.caption1, color: Colors.Text.secondary)
            }

            HStack(spacing: 0) {
                CustomTextField(text: text, isResponder: .constant(nil), actionButtonTapped: .constant(false), handleKeyboard: true, keyboard: keyboardType, textColor: isEnabled ? UIColor.textPrimary1 : UIColor.textDisabled, font: UIFonts.Regular.subheadline, placeholder: placeholder, isEnabled: isEnabled)
                    .opacity(isLoading ? 0 : 1)
                    .overlay(skeleton, alignment: .leading)

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var skeleton: some View {
        if isLoading {
            SkeletonView()
                .frame(size: CGSize(width: 90, height: 12))
                .cornerRadiusContinuous(3)
        }
    }
}

// MARK: - Preview

struct AddCustomTokenView_Preview: PreviewProvider {
    class PreviewManageTokensDataSource: MarketsDataSource {}

    static let userTokensManager: UserTokensManager = {
        let fakeUserTokenListManager = FakeUserTokenListManager(walletManagers: [], isDelayed: false)
        return FakeUserTokensManager(
            derivationManager: FakeDerivationManager(pendingDerivationsCount: 5),
            userTokenListManager: fakeUserTokenListManager
        )
    }()

    static let viewModel = AddCustomTokenViewModel(
        userWalletModel: FakeUserWalletRepository().models.first!,
        dataSource: PreviewManageTokensDataSource(),
        coordinator: AddCustomTokenCoordinator()
    )

    static var previews: some View {
        NavigationView {
            AddCustomTokenView(viewModel: viewModel)
        }
    }
}
