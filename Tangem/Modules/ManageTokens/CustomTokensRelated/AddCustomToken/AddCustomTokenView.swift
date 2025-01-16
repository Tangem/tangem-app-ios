//
//  AddCustomTokenView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 22.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddCustomTokenView: View {
    @ObservedObject var viewModel: AddCustomTokenViewModel

    @FocusState private var isFocusedAddressField: Bool
    @FocusState private var isFocusedNameField: Bool
    @FocusState private var isFocusedSymbolField: Bool
    @FocusState private var isFocusedDecimalsField: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(Localization.customTokenSubtitle)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 38)
                    .padding(.bottom, 22)

                if viewModel.selectedBlockchainNetworkId == nil {
                    networkSelectorContent
                } else {
                    mainContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        .onAppear(perform: viewModel.onAppear)
        .alert(item: $viewModel.alert, content: { $0.alert })
        .navigationBarTitle(Text(Localization.addCustomTokenTitle), displayMode: .inline)
        .animation(.default, value: viewModel.selectedBlockchainNetworkId)
    }

    private var networkSelectorContent: some View {
        LazyVStack(alignment: .leading) {
            Text(Localization.addCustomTokenChooseNetwork)
                .style(Fonts.Bold.subheadline, color: Colors.Text.secondary)
                .padding(.horizontal, 8)

            AddCustomTokenNetworksListView(viewModel: viewModel.networkSelectorViewModel, isWithPadding: false)
        }
    }

    private var mainContent: some View {
        VStack(spacing: 14) {
            Button(action: viewModel.openNetworkSelector) {
                ItemSelectorRow(title: Localization.customTokenNetworkInputTitle, selectedItem: viewModel.selectedBlockchainName)
            }
            .defaultRoundedBackground(with: Colors.Background.action)

            if viewModel.selectedBlockchainSupportsTokens {
                tokenInputFields
            }

            if viewModel.showDerivationPaths {
                Button(action: viewModel.openDerivationSelector) {
                    ItemSelectorRow(title: Localization.customTokenDerivationPath, selectedItem: viewModel.selectedDerivationOption?.name ?? "")
                }
                .defaultRoundedBackground(with: Colors.Background.action)
            }

            if let notificationInput = viewModel.notificationInput {
                NotificationView(input: notificationInput)
            }

            MainButton(
                title: Localization.customTokenAddToken,
                icon: viewModel.showDerivationPaths ? .trailing(Assets.tangemIcon) : nil,
                isLoading: viewModel.isLoading,
                isDisabled: viewModel.addButtonDisabled,
                action: viewModel.createToken
            )
        }
    }

    private var tokenInputFields: some View {
        VStack(spacing: 0) {
            TextInputWithTitle(
                title: Localization.customTokenContractAddressInputTitle,
                placeholder: "0x0000000000000000000000000000000000000000",
                text: $viewModel.contractAddress,
                keyboardType: .default,
                autocapitalizationType: .none,
                isEnabled: true,
                isLoading: false,
                error: viewModel.contractAddressError
            )
            .focused($isFocusedAddressField)
            .onChange(of: isFocusedAddressField) { isFocused in
                guard !isFocused else { return }
                viewModel.onChangeFocusable(field: .address)
            }

            separator

            TextInputWithTitle(
                title: Localization.customTokenNameInputTitle,
                placeholder: Localization.customTokenNameInputPlaceholder,
                text: $viewModel.name,
                keyboardType: .default,
                autocapitalizationType: .words,
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
                autocapitalizationType: .allCharacters,
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
                autocapitalizationType: .none,
                isEnabled: true,
                isLoading: viewModel.isLoading,
                error: viewModel.decimalsError
            )
            .focused($isFocusedDecimalsField)
            .onChange(of: isFocusedDecimalsField) { isFocused in
                guard !isFocused else { return }
                viewModel.onChangeFocusable(field: .decimals)
            }
        }.roundedBackground(with: Colors.Background.action, padding: 0)
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
    }
}

// MARK: - Text input

private struct TextInputWithTitle: View {
    let title: String
    let placeholder: String
    let text: Binding<String>
    let keyboardType: UIKeyboardType
    let autocapitalizationType: UITextAutocapitalizationType
    let isEnabled: Bool
    let isLoading: Bool
    var error: Error?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .leadingFirstTextBaseline) {
                Text(error?.localizedDescription ?? "")
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
                    .hidden(error == nil)

                Text(title)
                    .style(Fonts.Regular.caption1, color: Colors.Text.secondary)
                    .hidden(error != nil)
            }

            HStack(spacing: 0) {
                customTextField
                    .opacity(isLoading ? 0 : 1)
                    .overlay(skeleton, alignment: .leading)

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .animation(.default, value: error == nil)
    }

    private var customTextField: some View {
        var customTextField = CustomTextField(
            text: text,
            isResponder: .constant(nil),
            actionButtonTapped: .constant(false),
            handleKeyboard: true,
            keyboard: keyboardType,
            textColor: isEnabled ? UIColor.textPrimary1 : UIColor.textDisabled,
            font: UIFonts.Regular.subheadline,
            placeholder: placeholder,
            isEnabled: isEnabled
        )
        customTextField.autocapitalizationType = autocapitalizationType

        return customTextField
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

#Preview {
    let userWalletModel = FakeUserWalletModel.wallet3Cards
    let coordinator = AddCustomTokenCoordinator()
    coordinator.start(with: .init(userWalletModel: userWalletModel, analyticsSourceRawValue: "preview"))

    return AddCustomTokenCoordinatorView(coordinator: coordinator)
}
