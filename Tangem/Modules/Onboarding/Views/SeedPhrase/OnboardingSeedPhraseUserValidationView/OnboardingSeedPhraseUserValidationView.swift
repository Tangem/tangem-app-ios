//
//  OnboardingSeedPhraseUserValidationView.swift
//  Tangem
//
//  Created by Andrew Son on 23/03/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSwiftUIUtils

struct OnboardingSeedPhraseUserValidationView: View {
    @ObservedObject var viewModel: OnboardingSeedPhraseUserValidationViewModel

    @State private var containerSize: CGSize = .zero
    @State private var contentSize: CGSize = .zero

    @State private var isButtonPositionAnimationEnabled = false

    var body: some View {
        VStack {
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
                        .frame(minHeight: max(20, containerSize.height - contentSize.height))
                }
                .readGeometry(\.size) { contentSize in
                    if self.contentSize == .zero {
                        self.contentSize = contentSize
                    }
                }
            }
            .readGeometry(\.size, inCoordinateSpace: .local) { containerSize in
                if self.containerSize != .zero, !isButtonPositionAnimationEnabled {
                    isButtonPositionAnimationEnabled = true
                }
                self.containerSize = containerSize
            }

            MainButton(
                title: Localization.onboardingCreateWalletButtonCreateWallet,
                icon: .trailing(Assets.tangemIcon),
                style: .primary,
                isLoading: false,
                isDisabled: !viewModel.isCreateWalletButtonEnabled,
                action: viewModel.createWallet
            )
            .padding(.bottom, 6)
        }
        .animation(isButtonPositionAnimationEnabled ? .easeOut(duration: 0.35) : nil, value: containerSize)
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
                .layoutPriority(1000.0)

            HStack(spacing: 0.0) {
                CustomTextField(
                    text: text,
                    isResponder: $isResponder,
                    actionButtonTapped: .constant(false),
                    clearsOnBeginEditing: false,
                    handleKeyboard: true,
                    keyboard: .asciiCapable,
                    clearButtonMode: .never,
                    textColor: UIColor(hasError ? Colors.Text.warning : Colors.Text.primary1),
                    font: UIFonts.Regular.body,
                    placeholder: "",
                    isEnabled: true
                )
                .setAutocapitalizationType(.none)
                .padding(.vertical, 12)

                if isResponder ?? false {
                    Button(action: { text.wrappedValue = "" }) {
                        Assets.clear.image
                            .foregroundColor(Colors.Icon.informative)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .screenCaptureProtection()
        }
        .frame(minHeight: 46)
        .background(Colors.Field.primary)
        .cornerRadiusContinuous(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(hasError ? Colors.Icon.warning : .clear, lineWidth: 1)
                .padding(.horizontal, 1) // offset the border to the inside, otherwise it cuts off
        )
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
