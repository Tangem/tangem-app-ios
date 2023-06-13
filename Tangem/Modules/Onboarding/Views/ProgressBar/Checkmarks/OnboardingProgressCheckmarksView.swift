//
//  OnboardingProgressCheckmarksView.swift
//  Tangem
//
//  Created by Andrew Son on 19.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct OnboardingProgressCheckmarksView: View {
    var numberOfSteps: Int
    var currentStep: Published<Int>.Publisher

    var checkmarksDiameter: CGFloat = 17
    var progressBarHeight: CGFloat = 3
    private let animDuration: TimeInterval = 0.3
    private let outerCircleDiameter: CGFloat = 31

    @State private var currentProgress: CGFloat = 0
    @State private var animatedSelectedIndex: Int = 0
    @State private var containerSize: CGSize = .zero
    @State private var selectionBackScale: CGFloat = 1
    @State private var selectionBackOffset: CGFloat = 0
    @State private var selectionIndex: Int = 0
    @State private var initialized: Bool = false

    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(.tangemGreen2)
                    .frame(size: .init(width: outerCircleDiameter, height: outerCircleDiameter))
                    .cornerRadius(outerCircleDiameter / 2)
                    .scaleEffect(selectionBackScale)
                    .offset(x: selectionBackOffset, y: 0)
                    .onAnimationCompleted(for: selectionBackScale) {
                        if selectionBackScale == 0.01 {
                            selectionBackOffset = calculateCircleOffset(for: selectionIndex) - (outerCircleDiameter / 2 - checkmarksDiameter / 2)
                            withAnimation(.linear(duration: initialized ? animDuration : 0).delay(initialized ? animDuration / 2 : 0)) {
                                selectionBackScale = 1
                            }
                            initialized = true
                        }
                    }
                Rectangle()
                    .modifier(AnimatableGradient(
                        backgroundColor: .tangemGreen2,
                        progressColor: .tangemGreen,
                        gradientStop: currentProgress
                    )
                    )
                    .frame(width: containerSize.width, height: 3)
                ForEach(0 ..< numberOfSteps) { stepIndex in
                    OnboardingProgressCircle(index: stepIndex, selectedIndex: animatedSelectedIndex)
                        .offset(
                            x: calculateCircleOffset(for: stepIndex),
                            y: 0
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .readSize { size in
                containerSize = size
            }
        }
        .onReceive(currentStep, perform: { newStep in
            animateSelection(at: newStep, animated: initialized)
            updateState(to: newStep, animated: initialized)
        })
    }

    private func animateSelection(at index: Int, animated: Bool) {
        withAnimation(.linear(duration: animated ? animDuration / 2 : 0)) {
            selectionBackScale = 0.01
        }
        selectionIndex = index
    }

    private func updateState(to index: Int, animated: Bool) {
        withAnimation(.linear(duration: animated ? animDuration : 0)) {
            currentProgress = min(1.0, CGFloat(index) / CGFloat(numberOfSteps - 1))
        }
        withAnimation(.linear(duration: animated ? animDuration : 0).delay(animated ? animDuration - 0.05 : 0)) {
            animatedSelectedIndex = index
        }
    }

    private func calculateCircleOffset(for index: Int) -> CGFloat {
        numberOfSteps <= 1 ?
            containerSize.width / 2 :
            (CGFloat(index) * (containerSize.width - checkmarksDiameter) / CGFloat(numberOfSteps - 1))
    }
}

private class Provider: ObservableObject {
    @Published var currentStep: Int = 10

    var numberOfSteps: Int { 6 }

    func goToNextStep() {
        var nextStep = currentStep + 1
        if nextStep > numberOfSteps {
            nextStep = 0
        }
        currentStep = nextStep
    }
}

struct OnboardingProgressCheckmarksPreview: View {
    @ObservedObject fileprivate var model: Provider

    var body: some View {
        VStack {
            OnboardingProgressCheckmarksView(
                numberOfSteps: model.numberOfSteps,
                currentStep: model.$currentStep
            )
            .padding(.horizontal, 40)
            Button(action: {
                model.goToNextStep()
            }, label: {
                Text("Step number: \(model.currentStep)")
                    .padding()
            })
        }
    }
}

struct OnboardingProgressCheckmarksView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingProgressCheckmarksPreview(model: Provider())
    }
}
