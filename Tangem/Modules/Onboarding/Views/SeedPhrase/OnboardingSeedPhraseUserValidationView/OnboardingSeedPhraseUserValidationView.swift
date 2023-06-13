//
//  OnboardingSeedPhraseUserValidationView.swift
//  Tangem
//
//  Created by Andrew Son on 23/03/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingSeedPhraseUserValidationView: View {
    @ObservedObject var viewModel: OnboardingSeedPhraseUserValidationViewModel

    @State private var containerSize: CGSize = .zero
    @State private var contentSize: CGSize = .zero

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Text(Localization.onboardingSeedUserValidationTitle)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .padding(.top, 40)

                Text(Localization.onboardingSeedUserValidationMessage)
                    .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 14)
                    .padding(.horizontal, 32)

                WordInputView(
                    wordNumber: 2,
                    hasError: viewModel.firstInputHasError,
                    text: $viewModel.firstInputText
                )
                .padding(.top, 38)

                WordInputView(
                    wordNumber: 7,
                    hasError: viewModel.secondInputHasError,
                    text: $viewModel.secondInputText
                )
                .padding(.top, 20)

                WordInputView(
                    wordNumber: 11,
                    hasError: viewModel.thirdInputHasError,
                    text: $viewModel.thirdInputText
                )
                .padding(.top, 20)

                Color.clear
                    .frame(minHeight: containerSize.height - contentSize.height)

                MainButton(
                    title: Localization.walletButtonCreateWallet,
                    icon: .leading(Assets.tangemIcon),
                    style: .primary,
                    isLoading: false,
                    isDisabled: !viewModel.isCreateWalletButtonEnabled,
                    action: viewModel.createWallet
                )
                .padding(.bottom, 10)
            }
            .readSize(onChange: { contentSize in
                if self.contentSize == .zero {
                    self.contentSize = contentSize
                }
            })
        }
        .readSize(onChange: { containerSize in
            if self.containerSize == .zero {
                self.containerSize = containerSize
            }
        })
        .padding(.horizontal, 16)
    }
}

private struct WordInputView: View {
    let wordNumber: Int
    let hasError: Bool
    let text: Binding<String>

    @State private var isResponder: Bool? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("\(wordNumber).")
                .style(
                    Fonts.Regular.body,
                    color: hasError ? Colors.Text.warning : Colors.Text.tertiary
                )
                .frame(width: 38, alignment: .leading)
                .padding(.leading, 16)

            CustomTextField(
                text: text,
                isResponder: $isResponder,
                actionButtonTapped: .constant(false),
                clearsOnBeginEditing: false,
                handleKeyboard: true,
                clearButtonMode: .never,
                textColor: UIColor(hasError ? Colors.Text.warning : Colors.Text.primary1),
                font: UIFonts.Regular.body,
                placeholder: "",
                isEnabled: true
            )
            .padding(.vertical, 12)

            if isResponder ?? false {
                Button(action: { text.wrappedValue = "" }) {
                    Assets.clear.image
                        .foregroundColor(Colors.Icon.informative)
                        .padding(.horizontal, 16)
                }
            }
        }
        .frame(minHeight: 46)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(hasError ? Colors.Icon.warning : .clear, lineWidth: 1)
        )
        .background(Colors.Field.focused)
        .cornerRadiusContinuous(14)
        .simultaneousGesture(TapGesture().onEnded {
            isResponder = true
        })
    }
}

struct OnboardingSeedPhraseUserValidationView_Previews: PreviewProvider {
    private static let viewModel = OnboardingSeedPhraseUserValidationViewModel(
        validationInput: .init(
            secondWord: "tree",
            seventhWord: "lunar",
            eleventhWord: "banana",
            createWalletAction: {}
        )
    )

    static var previews: some View {
        OnboardingSeedPhraseUserValidationView(viewModel: viewModel)
    }
}
