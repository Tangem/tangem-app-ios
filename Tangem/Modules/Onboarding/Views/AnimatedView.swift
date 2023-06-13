//
//  AnimatedView.swift
//  Tangem
//
//  Created by Andrew Son on 03.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct AnimatedViewSettings: Equatable {
    var targetSettings: CardAnimSettings
    var intermediateSettings: CardAnimSettings?

    static var zero: AnimatedViewSettings {
        .init(
            targetSettings: .zero,
            intermediateSettings: nil
        )
    }
}

struct AnimatedView<Content: View>: View {
    let content: Content
    let settings: Published<AnimatedViewSettings>.Publisher

    init(settings: Published<AnimatedViewSettings>.Publisher, @ViewBuilder content: () -> Content) {
        self.settings = settings
        self.content = content()
    }

    private enum AnimState {
        case notAnimating
        case toIntermediate
        case toTarget

        var progress: CGFloat {
            switch self {
            case .notAnimating: return 0
            case .toIntermediate: return 0.5
            case .toTarget: return 1
            }
        }
    }

    // TODO: Think about replacing AnimatedViewSettings with Array of CardAnimSettings
    @State var currentSettings: AnimatedViewSettings = .zero
    @State var lastSettings: AnimatedViewSettings!

    @State private var animationProgress: CGFloat = 0
    @State private var animState: AnimState = .notAnimating

    var body: some View {
        applySettings(content)
            .onAnimationCompleted(for: animationProgress, completion: {
                if animState == .toIntermediate {
                    launchAnimation(for: .toTarget, with: currentSettings.targetSettings)
                } else {
                    animState = .notAnimating
                    lastSettings = currentSettings
                    animationProgress = 0
                }
            })
            .onReceive(settings, perform: { newSettings in
                if lastSettings == nil {
                    lastSettings = newSettings
                    return
                }

                guard lastSettings != newSettings else { return }

                currentSettings = newSettings

                if let inter = newSettings.intermediateSettings {
                    launchAnimation(for: .toIntermediate, with: inter)
                } else {
                    launchAnimation(for: .toTarget, with: newSettings.targetSettings)
                }
            })
    }

    private func launchAnimation(for state: AnimState, with settings: CardAnimSettings) {
        guard let animation = settings.animation else {
            // TODO: refactor
            withAnimation(.linear(duration: 0.0001)) {
                animState = state
                animationProgress = state.progress
            }
            return
        }

        withAnimation(animation) {
            animState = state
            animationProgress = state.progress
        }
    }

    @ViewBuilder
    func applySettings<Content: View>(to view: Content, settings: CardAnimSettings) -> some View {
        view
            .frame(size: settings.frame)
            .rotationEffect(settings.rotationAngle)
            .scaleEffect(settings.scale)
            .offset(settings.offset)
            .opacity(settings.opacity)
            .zIndex(settings.zIndex)
    }

    @ViewBuilder
    private func applySettings<Content: View>(_ view: Content) -> some View {
        if let settings = selectSettings() {
            applySettings(to: view, settings: settings)
        } else {
            view
        }
    }

    private func selectSettings() -> CardAnimSettings? {
        if lastSettings == nil {
            return nil
        } else if animState == .notAnimating {
            return lastSettings!.targetSettings
        } else if let intermediate = currentSettings.intermediateSettings, animState == .toIntermediate {
            return intermediate
        } else {
            return currentSettings.targetSettings
        }
    }
}

private class AnimatedViewPreviewModel: ObservableObject {
    enum Step: String {
        case zero
        case first
        case second
        case third
        case fourth

        var next: Step {
            switch self {
            case .zero: return .first
            case .first: return .second
            case .second: return .third
            case .third: return .fourth
            case .fourth: return .zero
            }
        }

        var settings: AnimatedViewSettings {
            .init(
                targetSettings: target,
                intermediateSettings: intermediateOffset
            )
        }

        var target: CardAnimSettings {
            switch self {
            case .zero:
                return .zero
            case .first:
                return .init(
                    frame: .init(width: 75, height: 75),
                    offset: .init(width: 100, height: -100),
                    scale: 1.0,
                    opacity: 1,
                    zIndex: 1,
                    rotationAngle: .zero,
                    animType: .noAnim,
                    animDuration: 0.3
                )
            case .second:
                return .init(
                    frame: .init(width: 75, height: 75),
                    offset: .init(width: 100, height: 100),
                    scale: 0.5,
                    opacity: 0.4,
                    zIndex: 1,
                    rotationAngle: .init(degrees: 45),
                    animType: .linear,
                    animDuration: 0.3
                )
            case .third:
                return .init(
                    frame: .init(width: 75, height: 75),
                    offset: .init(width: -100, height: 100),
                    scale: 0.7,
                    opacity: 0.8,
                    zIndex: 1,
                    rotationAngle: .init(degrees: 135),
                    animType: .linear,
                    animDuration: 0.3
                )
            case .fourth:
                return .init(
                    frame: .init(width: 75, height: 75),
                    offset: .init(width: -100, height: -100),
                    scale: 1,
                    opacity: 1,
                    zIndex: 1,
                    rotationAngle: .init(degrees: 270),
                    animType: .linear,
                    animDuration: 0.3
                )
            }
        }

        var intermediateOffset: CardAnimSettings {
            switch self {
            case .zero:
                return .zero
            case .first:
                return .init(
                    frame: .init(width: 75, height: 75),
                    offset: .init(width: -20, height: -40),
                    scale: 0.6,
                    opacity: 0.4,
                    zIndex: 1,
                    rotationAngle: .zero,
                    animType: .linear,
                    animDuration: 0.3
                )
            case .second:
                return .init(
                    frame: .init(width: 75, height: 75),
                    offset: .init(width: 150, height: 0),
                    scale: 0.5,
                    opacity: 0.4,
                    zIndex: 1,
                    rotationAngle: .init(degrees: 45),
                    animType: .linear,
                    animDuration: 0.3
                )
            case .third:
                return .init(
                    frame: .init(width: 75, height: 75),
                    offset: .init(width: 0, height: 30),
                    scale: 0.7,
                    opacity: 0.8,
                    zIndex: 1,
                    rotationAngle: .init(degrees: 135),
                    animType: .linear,
                    animDuration: 0.3
                )
            case .fourth:
                return .init(
                    frame: .init(width: 75, height: 75),
                    offset: .init(width: -30, height: 20),
                    scale: 1,
                    opacity: 1,
                    zIndex: 1,
                    rotationAngle: .init(degrees: 270),
                    animType: .linear,
                    animDuration: 0.3
                )
            }
        }
    }

    @Published var step: Step = .zero
    @Published var settings: AnimatedViewSettings = .zero

    func next() {
        step = step.next
        settings = step.settings
    }
}

private struct AnimatedViewPreview: View {
    @ObservedObject var viewModel: AnimatedViewPreviewModel

    var body: some View {
        GeometryReader { geom in
            ZStack(alignment: .center) {
                AnimatedView(settings: viewModel.$settings) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue)
                        .frame(size: .init(width: 75, height: 75))
                }
                Button(action: {
                    viewModel.next()
                }, label: {
                    Text("Next")
                        .padding()
                })
                .offset(x: 0, y: 100)
                Text("\(viewModel.step.rawValue)")
                    .offset(x: 0, y: 200)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.red.opacity(0.4))
        }
    }
}

struct AnimatedView_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedViewPreview(viewModel: AnimatedViewPreviewModel())
    }
}
