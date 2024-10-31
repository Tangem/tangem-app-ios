//
//  OnboardingTextButtonView.swift
//  Tangem
//
//  Created by Andrew Son on 14.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingBottomButtonsSettings {
    let main: MainButton.Settings?
    let supplement: MainButton.Settings?
}

struct OnboardingTextButtonView: View {
    let title: String?
    let subtitle: String?
    var textOffset: CGSize = .zero
    let buttonsSettings: OnboardingBottomButtonsSettings
    let infoText: String?
    let titleAction: (() -> Void)?
    var checkmarkText: String?
    var isCheckmarkChecked: Binding<Bool> = .constant(false)

    var buttons: some View {
        VStack(spacing: 10) {
            MainButton(
                title: buttonsSettings.main?.title ?? "",
                icon: buttonsSettings.main?.icon,
                style: buttonsSettings.main?.style ?? .primary,
                isLoading: buttonsSettings.main?.isLoading ?? false,
                isDisabled: buttonsSettings.main?.isDisabled ?? false
            ) {
                withAnimation {
                    buttonsSettings.main?.action()
                }
            }
            // For now we need to leave view in the hierarchy to prevent
            // issues with drawing card images
            .hidden(buttonsSettings.main == nil)

            MainButton(
                title: buttonsSettings.supplement?.title ?? "",
                icon: buttonsSettings.supplement?.icon,
                style: buttonsSettings.supplement?.style ?? .secondary,
                isLoading: buttonsSettings.supplement?.isLoading ?? false,
                isDisabled: buttonsSettings.supplement?.isDisabled ?? false
            ) {
                withAnimation {
                    buttonsSettings.supplement?.action()
                }
            }
            // For now we need to leave view in the hierarchy to prevent
            // issues with drawing card images
            .hidden(buttonsSettings.supplement == nil)
        }
    }

    @ViewBuilder
    var infoTextView: some View {
        if let infoText = infoText {
            Text(infoText)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let title = title, let subtitle = subtitle {
                OnboardingMessagesView(
                    title: title,
                    subtitle: subtitle
                ) {
                    titleAction?()
                }
                .frame(alignment: .top)
                .padding(.horizontal, 34)
                .offset(textOffset)

                Spacer()
            }

            if let checkmarkText = checkmarkText {
                HStack {
                    CheckmarkSwitch(
                        isChecked: isCheckmarkChecked,
                        settings: .defaultRoundedRect()
                    )
                    .frame(size: .init(width: 26, height: 26))
                    Text(checkmarkText).bold()
                        .onTapGesture {
                            withAnimation {
                                isCheckmarkChecked.wrappedValue.toggle()
                            }
                        }
                }

                Spacer()
            }

            buttons
                .padding(.bottom, 6)
                .padding(.horizontal, 16)
        }
        .frame(maxHeight: 304)
    }
}

struct OnboardingTextButtonView_Previews: PreviewProvider {
    @State static var isChecked: Bool = false

    static var previews: some View {
        OnboardingTextButtonView(
            title: "Create wallet",
            subtitle: "Let's generate all the keys on your card and create a secure wallet",
            textOffset: .init(width: 0, height: -100),
            buttonsSettings:
            .init(
                main: MainButton.Settings(
                    title: "Create wallet",
                    isLoading: false,
                    isDisabled: false,
                    action: {}
                ),
                supplement: .init(
                    title: "Other options",
                    action: {}
                )
            ),
            infoText: nil,
            titleAction: {},
            checkmarkText: "I understand",
            isCheckmarkChecked: $isChecked
        )
        .padding(.horizontal, 40)
    }
}
