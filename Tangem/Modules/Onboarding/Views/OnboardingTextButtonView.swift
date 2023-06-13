//
//  OnboardingTextButtonView.swift
//  Tangem
//
//  Created by Andrew Son on 14.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct TangemButtonSettings {
    let title: String
    let size: ButtonLayout
    let action: (() -> Void)?
    let isBusy: Bool
    var isEnabled: Bool
    let isVisible: Bool

    var color: ButtonColorStyle = .black
    var customIconName: String = ""
    var systemIconName: String = ""
    var iconPosition: TangemButton.IconPosition = .trailing
}

struct OnboardingBottomButtonsSettings {
    let main: MainButton.Settings?

    var supplement: TangemButtonSettings?
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

    @ViewBuilder
    var buttons: some View {
        VStack(spacing: 10) {
            if let mainSettings = buttonsSettings.main {
                MainButton(
                    title: mainSettings.title,
                    icon: mainSettings.icon,
                    style: mainSettings.style,
                    isLoading: mainSettings.isLoading,
                    isDisabled: mainSettings.isDisabled
                ) {
                    withAnimation {
                        mainSettings.action()
                    }
                }
            }

            // TODO: Refactor to `MainButton` and for dark theme
            if let settings = buttonsSettings.supplement {
                //            if buttonsSettings.containSupplementButton {
                TangemButton(title: settings.title) {
                    settings.action?()
                }
                .opacity(settings.isVisible ? 1.0 : 0.0)
                .buttonStyle(TangemButtonStyle(
                    colorStyle: settings.color,
                    layout: settings.size,
                    isDisabled: !settings.isEnabled,
                    isLoading: settings.isBusy
                ))
                .overlay(infoTextView)
            }
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
                .padding(.bottom, buttonsSettings.supplement != nil ? 16 : 20)
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
                supplement: TangemButtonSettings(
                    title: "What does it mean?",
                    size: .wide,
                    action: {},
                    isBusy: false,
                    isEnabled: false,
                    isVisible: true,
                    color: .grayAlt,
                    systemIconName: "plus",
                    iconPosition: .leading
                )
            ),
            infoText: nil,
            titleAction: {},
            checkmarkText: "I understand",
            isCheckmarkChecked: $isChecked
            //                .init(
            //                mainTitle: "Create wallet",
            //                mainSize: .wide,
            //                mainAction: {
            //
            //                },
            //                mainIsBusy: false,
            //                isMainEnabled: true,
            //                supplementTitle: "What does it mean?",
            //                supplementSize: .wide,
            //                supplementAction: {
            //
            //                },
            //                isVisible: true,
            //                containSupplementButton: false),
            //            titleAction: { }
        )
        .padding(.horizontal, 40)
    }
}
