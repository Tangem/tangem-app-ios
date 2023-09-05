//
//  OnboardingCircleButton.swift
//  Tangem
//
//  Created by Andrew Son on 12.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingCircleButton: View {
    enum State {
        case blank
        case refreshButton
        case activityIndicator
        case doneCheckmark
    }

    enum Size {
        case `default`
        case huge
        case medium
        case small

        var buttonSize: CGSize {
            switch self {
            case .default: return .init(width: 68, height: 68)
            case .huge: return .init(width: 140, height: 140)
            case .medium: return .init(width: 60, height: 60)
            case .small: return .init(width: 44, height: 44)
            }
        }

        var activityIndicatorStyle: UIActivityIndicatorView.Style {
            switch self {
            case .default, .huge: return .large
            case .medium, .small: return .medium
            }
        }

        var refreshImageSize: CGSize {
            switch self {
            case .default: return .init(width: 30, height: 30)
            case .huge: return .init(width: 70, height: 70)
            case .medium: return .init(width: 26, height: 26)
            case .small: return .init(width: 18, height: 18)
            }
        }

        var checkmarkSize: CGSize {
            switch self {
            case .default: return .init(width: 18, height: 18)
            case .huge: return .init(width: 36, height: 36)
            case .medium: return .init(width: 15, height: 15)
            case .small: return .init(width: 12, height: 12)
            }
        }
    }

    var refreshAction: () -> Void
    var state: State
    var size: Size = .default

    private let backgroundColor = Colors.Background.primary
    private var buttonSize: CGSize { size.buttonSize }
    private var successButtonSize: CGSize {
        .init(width: buttonSize.width * 0.657, height: buttonSize.height * 0.657)
    }

    @ViewBuilder
    var backgroundView: some View {
        ZStack {
            Button(action: {
                refreshAction()
            }, label: {
                Circle()
                    .foregroundColor(backgroundColor)
                    .overlay(
                        Assets.Onboarding.refresh.image
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(state == .refreshButton ? .tangemGrayDark6 : backgroundColor)
                            .frame(size: size.refreshImageSize)
                    )
            })
            .allowsHitTesting(state == .refreshButton)
            ActivityIndicatorView(
                isAnimating: state == .activityIndicator,
                style: size.activityIndicatorStyle,
                color: .tangemGrayDark6
            )
            .frame(size: buttonSize)
            .background(backgroundColor)
            .cornerRadius(buttonSize.height / 2)
            .opacity(state == .activityIndicator ? 1.0 : 0.0)
            Circle()
                .frame(size: buttonSize)
                .foregroundColor(Colors.Icon.accent)
                .opacity(0.2)
                .cornerRadius(buttonSize.height / 2)
                .scaleEffect(state == .doneCheckmark ? 1.0 : 0.0001)
            Colors.Icon.accent
                .frame(size: successButtonSize)
                .cornerRadius(successButtonSize.height)
                .overlay(
                    Assets.Onboarding.designCheckmark.image
                        .resizable()
                        .frame(size: size.checkmarkSize)
                        .cornerRadius(buttonSize.height / 2)
                )
                .scaleEffect(state == .doneCheckmark ? 1.0 : 0.0001)
        }
    }

    var body: some View {
        Circle()
            .strokeBorder(style: StrokeStyle(lineWidth: 1))
            .foregroundColor(state == .doneCheckmark ? Colors.Icon.accent : .tangemGrayLight4)
            .background(backgroundView)
            .frame(size: buttonSize)
    }
}

struct OnboardingCircleButton_Previews: PreviewProvider {
    static var previews: some View {
        Color.yellow
            .overlay(
                VStack {
                    HStack {
                        VStack {
                            OnboardingCircleButton(refreshAction: {}, state: .refreshButton, size: .default)
                            OnboardingCircleButton(refreshAction: {}, state: .refreshButton, size: .medium)
                            OnboardingCircleButton(refreshAction: {}, state: .refreshButton, size: .small)
                        }

                        VStack {
                            OnboardingCircleButton(refreshAction: {}, state: .activityIndicator, size: .default)
                            OnboardingCircleButton(refreshAction: {}, state: .activityIndicator, size: .medium)
                            OnboardingCircleButton(refreshAction: {}, state: .activityIndicator, size: .small)
                        }

                        VStack {
                            OnboardingCircleButton(refreshAction: {}, state: .doneCheckmark, size: .default)
                            OnboardingCircleButton(refreshAction: {}, state: .doneCheckmark, size: .medium)
                            OnboardingCircleButton(refreshAction: {}, state: .doneCheckmark, size: .small)
                        }

                        VStack {
                            OnboardingCircleButton(refreshAction: {}, state: .blank, size: .default)
                            OnboardingCircleButton(refreshAction: {}, state: .blank, size: .medium)
                            OnboardingCircleButton(refreshAction: {}, state: .blank, size: .small)
                        }
                    }
                    HStack(spacing: 0) {
                        OnboardingCircleButton(refreshAction: {}, state: .refreshButton, size: .huge)
                        OnboardingCircleButton(refreshAction: {}, state: .activityIndicator, size: .huge)
                        OnboardingCircleButton(refreshAction: {}, state: .doneCheckmark, size: .huge)
                    }
                }
            )
    }
}
