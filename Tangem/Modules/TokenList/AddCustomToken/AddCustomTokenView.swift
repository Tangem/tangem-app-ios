//
//  AddCustomTokenView.swift
//  Tangem
//
//  Created by Andrew Son on 11/02/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

struct AddCustomTokenView: View {
    @ObservedObject var viewModel: AddCustomTokenViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                VStack(spacing: 1) {
                    PickerInputWithTitle(title: Localization.customTokenNetworkInputTitle, model: $viewModel.blockchainsPicker)
                        .cornerRadius(10, corners: [.topLeft, .topRight])

                    if viewModel.canEnterTokenDetails {
                        TextInputWithTitle(title: Localization.customTokenContractAddressInputTitle, placeholder: "0x0000000000000000000000000000000000000000", text: $viewModel.contractAddress, keyboardType: .default, isEnabled: true, isLoading: viewModel.isLoading)

                        TextInputWithTitle(title: Localization.customTokenNameInputTitle, placeholder: Localization.customTokenNameInputPlaceholder, text: $viewModel.name, keyboardType: .default, isEnabled: viewModel.canEnterTokenDetails, isLoading: false)

                        TextInputWithTitle(title: Localization.customTokenTokenSymbolInputTitle, placeholder: Localization.customTokenTokenSymbolInputPlaceholder, text: $viewModel.symbol, keyboardType: .default, isEnabled: viewModel.canEnterTokenDetails, isLoading: false)

                        TextInputWithTitle(title: Localization.customTokenDecimalsInputTitle, placeholder: "0", text: $viewModel.decimals, keyboardType: .numberPad, isEnabled: viewModel.canEnterTokenDetails, isLoading: false)
                            .cornerRadius(viewModel.showDerivationPaths ? 0 : 10, corners: [.bottomLeft, .bottomRight])
                    }

                    if viewModel.showDerivationPaths {
                        PickerInputWithTitle(title: Localization.customTokenDerivationPathInputTitle, model: $viewModel.derivationsPicker)
                            .cornerRadius(viewModel.showCustomDerivationPath ? 0 : 10, corners: [.bottomLeft, .bottomRight])

                        if viewModel.showCustomDerivationPath {
                            TextInputWithTitle(title: Localization.customTokenCustomDerivation, placeholder: "m/44'/0'/0'/0/0", text: $viewModel.customDerivationPath, keyboardType: .default, isEnabled: true, isLoading: false)
                                .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
                        }
                    }
                }

                WarningListView(warnings: viewModel.warningContainer, warningButtonAction: { _, _, _ in })

                MainButton(
                    title: Localization.customTokenAddToken,
                    icon: .leading(Assets.plusMini),
                    isLoading: viewModel.isLoading,
                    isDisabled: viewModel.addButtonDisabled,
                    action: viewModel.createToken
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .alert(item: $viewModel.error, content: { $0.alert })
        .navigationBarTitle(Text(Localization.addCustomTokenTitle), displayMode: .inline) // fix ios14 navbar overlap
    }
}

// TODO: Refactor? Combine together? Is this stuff going to survive the redesign?
private struct TextInputWithTitle: View {
    var title: String
    var placeholder: String
    var text: Binding<String>
    var keyboardType: UIKeyboardType
    var height: CGFloat = 60
    var backgroundColor: Color = .white
    let isEnabled: Bool
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color.tangemGrayDark6)

            HStack {
                CustomTextField(text: text, isResponder: .constant(nil), actionButtonTapped: .constant(false), handleKeyboard: true, keyboard: keyboardType, textColor: isEnabled ? UIColor.tangemGrayDark4 : .lightGray, font: UIFont.systemFont(ofSize: 17, weight: .regular), placeholder: placeholder, isEnabled: isEnabled)

                if isLoading {
                    ActivityIndicatorView(isAnimating: true, color: .tangemGrayDark)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(backgroundColor)
    }
}

private struct PickerInputWithTitle: View {
    var title: String
    var height: CGFloat = 60
    var backgroundColor: Color = .white
    @Binding var model: PickerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color.tangemGrayDark6)

            HStack {
                Picker("", selection: $model.selection) {
                    ForEach(model.items, id: \.1) { value in
                        Text(value.0)
                            .minimumScaleFactor(0.7)
                            .tag(value.1)
                    }
                }
                .id(model.id)
                .modifier(PickerStyleModifier())
                .disabled(!model.isEnabled)
                .modifier(PickerAlignmentModifier())

                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(backgroundColor)
    }
}

// MARK: - Modifiers

private struct PickerAlignmentModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content
                .padding(.leading, -12)
        } else {
            content
        }
    }
}

private struct PickerStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .pickerStyle(.menu)
        } else {
            content
                .pickerStyle(.wheel)
        }
    }
}

struct AddCustomTokenView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = ManageTokensSettings(
            supportedBlockchains: SupportedBlockchains.all,
            hdWalletsSupported: true,
            longHashesSupported: true,
            derivationStyle: .v3,
            shouldShowLegacyDerivationAlert: false
        )

        let viewModel = AddCustomTokenViewModel(
            settings: settings,
            userTokensManager: UserTokensManagerMock(),
            coordinator: TokenListCoordinator()
        )

        AddCustomTokenView(viewModel: viewModel)
    }
}
