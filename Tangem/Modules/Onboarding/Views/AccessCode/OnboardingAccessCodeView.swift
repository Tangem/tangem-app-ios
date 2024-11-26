//
//  OnboardingAccessCodeView.swift
//  Tangem
//
//  Created by Andrew Son on 27.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

private struct AccessCodeFeature: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let icon: ImageType
}

struct OnboardingAccessCodeView: View {
    @ObservedObject var viewModel: OnboardingAccessCodeViewModel

    private let navbarHeight: CGFloat = 54

    var body: some View {
        VStack(spacing: 0) {
            NavigationBar(
                title: "",
                settings: .init(backgroundColor: .clear, height: navbarHeight),
                leftItems: {
                    BackButton(
                        height: navbarHeight,
                        isVisible: viewModel.state.isBackButtonVisible,
                        isEnabled: true
                    ) {
                        viewModel.backButtonAction()
                    }
                },
                rightItems: {}
            )

            content

            Spacer()

            MainButton(title: viewModel.state.buttonTitle, action: viewModel.mainButtonAction)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
        }
        .onDisappear(perform: viewModel.onDisappearAction)
        .animation(.default, value: viewModel.error)
        .animation(.default, value: viewModel.state)
    }

    private var titleView: some View {
        VStack(spacing: 10) {
            Text(viewModel.state.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .minimumScaleFactor(0.3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
                .lineLimit(2)
                .id("title_\(viewModel.state.rawValue)")

            if let hint = viewModel.state.hint {
                Text(hint)
                    .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .intro:
            VStack(spacing: 0) {
                Assets.Onboarding.inputWithLock.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.inactive)
                    .scaleEffect(AppConstants.isSmallScreen ? 0.7 : 1)

                titleView
                    .padding(.top, 12)

                featuresView
                    .padding(.top, 44)
                    .padding(.horizontal, 36)

                Spacer()
            }
            .padding(.top, AppConstants.isSmallScreen ? 0 : 20)

        case .inputCode, .repeatCode:
            VStack(spacing: 0) {
                titleView

                inputContent
                    .padding(.top, 32)
                    .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, AppConstants.isSmallScreen ? 0 : 30)
        }
    }

    private var inputContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            CustomPasswordTextField(
                placeholder: Localization.detailsManageSecurityAccessCode,
                color: Colors.Text.primary1,
                password: viewModel.state == .inputCode ? $viewModel.firstEnteredCode : $viewModel.secondEnteredCode,
                onCommit: {}
            )
            .frame(height: 46)

            Text(viewModel.error.description)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .style(Fonts.Regular.footnote, color: Colors.Text.warning)
                .id("error_\(viewModel.error.rawValue)")
                .hidden(viewModel.error.isErrorHidden)
        }
    }

    private var featuresView: some View {
        VStack(alignment: .leading, spacing: 28) {
            ForEach(ViewState.featuresDescription, id: \.self) { feature in
                HStack(alignment: .center, spacing: 16) {
                    feature.icon.image
                        .renderingMode(.template)
                        .foregroundStyle(Colors.Icon.primary1)
                        .frame(width: 42, height: 42, alignment: .center)
                        .background(
                            Colors.Background.secondary
                                .clipShape(Circle())
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(feature.title)
                            .style(Fonts.Bold.callout, color: Colors.Icon.primary1)

                        Text(feature.description)
                            .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

extension OnboardingAccessCodeView {
    enum ViewState: String {
        case intro
        case inputCode
        case repeatCode

        var title: String {
            switch self {
            case .intro, .inputCode: return Localization.onboardingAccessCodeIntroTitle
            case .repeatCode: return Localization.onboardingAccessCodeRepeatCodeTitle
            }
        }

        var hint: String? {
            switch self {
            case .intro: return nil
            case .inputCode: return Localization.onboardingAccessCodeHint
            case .repeatCode: return Localization.onboardingAccessCodeRepeatCodeHint
            }
        }

        var buttonTitle: String {
            switch self {
            case .intro: return Localization.commonCreate
            case .inputCode: return Localization.commonContinue
            case .repeatCode: return Localization.commonSubmit
            }
        }

        var isBackButtonVisible: Bool {
            switch self {
            case .intro, .inputCode: return false
            case .repeatCode: return true
            }
        }

        fileprivate static var featuresDescription: [AccessCodeFeature] {
            [
                .init(
                    title: Localization.onboardingAccessCodeFeature1Title,
                    description: Localization.onboardingAccessCodeFeature1Description,
                    icon: Assets.lock24
                ),
                .init(
                    title: Localization.onboardingAccessCodeFeature2Title,
                    description: Localization.onboardingAccessCodeFeature2Description,
                    icon: Assets.cog24
                ),
                .init(
                    title: Localization.onboardingAccessCodeFeature3Title,
                    description: Localization.onboardingAccessCodeFeature3Description,
                    icon: Assets.roundArrow24
                ),
            ]
        }
    }

    enum AccessCodeError: String {
        case none
        case tooShort
        case dontMatch

        var description: String {
            switch self {
            case .none: return ""
            case .tooShort: return Localization.onboardingAccessCodeTooShort
            case .dontMatch: return Localization.onboardingAccessCodesDoesntMatch
            }
        }

        var isErrorHidden: Bool {
            switch self {
            case .none: return true
            default: return false
            }
        }
    }
}

struct OnboardingAccessCodeView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingAccessCodeView(viewModel: .init(successHandler: { _ in }))
    }
}
