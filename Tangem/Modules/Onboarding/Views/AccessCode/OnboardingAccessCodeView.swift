//
//  OnboardingAccessCodeView.swift
//  Tangem
//
//  Created by Andrew Son on 27.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

private struct AccessCodeFeature {
    let title: String
    let description: String
    let icon: ImageType
}

struct OnboardingAccessCodeViewModel: Identifiable {
    let id: UUID = .init()
    let successHandler: (String) -> Void
}

struct OnboardingAccessCodeView: View {
    let viewModel: OnboardingAccessCodeViewModel

    @State private var state: ViewState = .intro
    @State private var firstEnteredCode: String = ""
    @State private var secondEnteredCode: String = ""
    @State private var error: AccessCodeError = .none

    @ViewBuilder
    var content: some View {
        switch state {
        case .intro:
            Spacer()
            Assets.Onboarding.inputWithLock.image
                .scaleEffect(AppConstants.isSmallScreen ? 0.7 : 1)
            Spacer()
            VStack(alignment: .leading, spacing: 20) {
                ForEach(0 ..< 3) { index in
                    let feature = ViewState.featuresDescription[index]
                    HStack(alignment: .customTop, spacing: 20) {
                        feature.icon.image
                            .alignmentGuide(.customTop) { d in d[VerticalAlignment.top] - 4 }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(feature.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.tangemGrayDark6)
                            Text(feature.description)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.tangemGrayDark2)
                                .fixedSize(horizontal: false, vertical: true)
                                .alignmentGuide(.customTop) { d in d[VerticalAlignment.top] }
                        }
                    }
                }
            }
            .padding(.horizontal, AppConstants.isSmallScreen ? 0 : 10)
        case .inputCode, .repeatCode:
            inputContent
        }
    }

    @ViewBuilder
    var inputContent: some View {
        Text(Localization.onboardingAccessCodeHint)
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.tangemGrayDark6)
            .padding(.bottom, 32)
            .padding(.top, 13)
            .multilineTextAlignment(.center)
        CustomPasswordTextField(
            placeholder: Localization.detailsManageSecurityAccessCode,
            color: .tangemGrayDark6,
            password: state == .inputCode ? $firstEnteredCode : $secondEnteredCode,
            onCommit: {}
        )
        .frame(height: 44)
    }

    var body: some View {
        VStack {
            Text(state.title)
                .minimumScaleFactor(0.3)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .foregroundColor(.tangemGrayDark6)
                .padding(.top, AppConstants.isSmallScreen ? 20 : 72)
                .lineLimit(2)
                .id("title_\(state.rawValue)")
                .onTapGesture {
                    withAnimation {
                        state = .intro
                        firstEnteredCode = ""
                        secondEnteredCode = ""
                    }
                }

            content

            Text(error.description)
                .id("error_\(error.rawValue)")
                .multilineTextAlignment(.center)
                .font(.system(size: 15, weight: .regular))
                .opacity(error.errorOpacity)
                .foregroundColor(.tangemCritical)
            Spacer()
            MainButton(title: state.buttonTitle) {
                let nextState: ViewState
                switch state {
                case .intro:
                    Analytics.log(.settingAccessCodeStarted)
                    nextState = .inputCode
                case .inputCode:
                    guard isAccessCodeValid() else {
                        return
                    }

                    Analytics.log(.accessCodeEntered)
                    nextState = .repeatCode
                case .repeatCode:
                    guard isAccessCodeValid() else {
                        return
                    }

                    Analytics.log(.accessCodeReEntered)
                    viewModel.successHandler(secondEnteredCode)
                    return
                }

                state = nextState
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 40)
        .onDisappear {
            DispatchQueue.main.async {
                error = .none
            }
        }
    }

    private func isAccessCodeValid() -> Bool {
        var error: AccessCodeError = .none
        switch state {
        case .intro: break
        case .inputCode:
            error = firstEnteredCode.count >= 4 ? .none : .tooShort
        case .repeatCode:
            error = firstEnteredCode == secondEnteredCode ? .none : .dontMatch
        }

        withAnimation {
            self.error = error
        }
        return error == .none
    }
}

struct CustomPasswordTextField: View {
    let placeholder: String
    let color: Color
    var backgroundColor: Color = .tangemBgGray2

    var password: Binding<String>

    var onEditingChanged: (Bool) -> Void = { _ in }
    var onCommit: () -> Void = {}
    /// iOS15+
    var shouldBecomeFirstResponder: Bool = true

    @State var isSecured: Bool = true

    @ViewBuilder
    var input: some View {
        if #available(iOS 15.0, *) {
            FocusableTextField(
                isSecured: isSecured,
                shouldBecomeFirstResponder: shouldBecomeFirstResponder,
                placeholder: placeholder,
                text: password,
                onEditingChanged: onEditingChanged,
                onCommit: onCommit
            )
        } else {
            legacyInput
        }
    }

    @ViewBuilder
    private var legacyInput: some View {
        if isSecured {
            SecureField(
                placeholder,
                text: password,
                onCommit: onCommit
            )
        } else {
            TextField(
                placeholder,
                text: password,
                onEditingChanged: onEditingChanged,
                onCommit: onCommit
            )
        }
    }

    var body: some View {
        GeometryReader { geom in
            HStack(spacing: 8) {
                input
                    .autocapitalization(.none)
                    .transition(.opacity)
                    .foregroundColor(color)
                    .keyboardType(.default)
                    .disableAutocorrection(true)
                Button(action: {
                    withAnimation {
                        isSecured.toggle()
                    }
                }, label: {
                    Image(systemName: isSecured ? "eye" : "eye.slash")
                        .foregroundColor(color)
                        .frame(width: geom.size.height, height: geom.size.height, alignment: .center)
                })
            }
            .padding(.leading, 16)
            .background(Color.tangemBgGray2)
            .cornerRadius(10)
        }
    }
}

@available(iOS 15.0, *)
private extension CustomPasswordTextField {
    enum Field: Hashable {
        case secure
        case plain
    }

    struct FocusableTextField: View {
        let isSecured: Bool
        let shouldBecomeFirstResponder: Bool
        let placeholder: String
        let text: Binding<String>
        var onEditingChanged: (Bool) -> Void = { _ in }
        var onCommit: () -> Void = {}

        @FocusState private var focusedField: Field?

        var body: some View {
            ZStack {
                if isSecured {
                    SecureField(
                        placeholder,
                        text: text,
                        onCommit: onCommit
                    )
                    .focused($focusedField, equals: .secure)
                } else {
                    TextField(
                        placeholder,
                        text: text,
                        onEditingChanged: onEditingChanged,
                        onCommit: onCommit
                    )
                    .focused($focusedField, equals: .plain)
                }
            }
            .keyboardType(.default)
            .onAppear(perform: onAppear)
            .onChange(of: isSecured) { newValue in
                setFocus(for: newValue)
            }
        }

        private func setFocus(for value: Bool) {
            focusedField = value ? .secure : .plain
        }

        private func onAppear() {
            if shouldBecomeFirstResponder {
                // Works only with huge delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    setFocus(for: isSecured)
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

        var buttonTitle: String {
            switch self {
            case .intro: return Localization.commonContinue
            case .inputCode: return Localization.commonContinue
            case .repeatCode: return Localization.commonSubmit
            }
        }

        fileprivate static var featuresDescription: [AccessCodeFeature] {
            [
                .init(
                    title: Localization.onboardingAccessCodeFeature1Title,
                    description: Localization.onboardingAccessCodeFeature1Description,
                    icon: Assets.Onboarding.accessCodeFeature1
                ),
                .init(
                    title: Localization.onboardingAccessCodeFeature2Title,
                    description: Localization.onboardingAccessCodeFeature2Description,
                    icon: Assets.Onboarding.accessCodeFeature2
                ),
                .init(
                    title: Localization.onboardingAccessCodeFeature3Title,
                    description: Localization.onboardingAccessCodeFeature3Description,
                    icon: Assets.Onboarding.accessCodeFeature3
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

        var errorOpacity: Double {
            switch self {
            case .none: return 0
            default: return 1
            }
        }
    }
}

struct OnboardingAccessCodeView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingAccessCodeView(viewModel: .init(successHandler: { _ in }))
    }
}
