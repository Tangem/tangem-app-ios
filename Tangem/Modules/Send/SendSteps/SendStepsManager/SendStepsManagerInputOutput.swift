//
//  SendStepsManagerInputOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SendStepsManagerInput: AnyObject {
//    var currentStep: SendStep { get }
}

protocol SendStepsManagerOutput: AnyObject {
//    func update(step: SendStep, animation: SendView.StepAnimation)

//    func update(mainButtonType: SendMainButtonType)
//    func update(backButtonVisible: Bool)
    func update(state: SendStepsManagerViewState)
}

struct SendStepsManagerViewState {
    let step: SendStep
    let animation: SendView.StepAnimation
    let mainButtonType: SendMainButtonType
    let backButtonVisible: Bool

    static func next(step: SendStep) -> SendStepsManagerViewState {
        SendStepsManagerViewState(
            step: step,
            animation: .slideForward,
            mainButtonType: .next,
            backButtonVisible: true
        )
    }

    static func back(step: SendStep) -> SendStepsManagerViewState {
        SendStepsManagerViewState(
            step: step,
            animation: .slideBackward,
            mainButtonType: .next,
            backButtonVisible: false
        )
    }

    static func moveAndFade(step: SendStep, action: SendMainButtonType) -> SendStepsManagerViewState {
        SendStepsManagerViewState(
            step: step,
            animation: .moveAndFade,
            mainButtonType: action,
            backButtonVisible: false
        )
    }

//    static func close(step: SendStep) -> SendStepsManagerViewState {
//        SendStepsManagerViewState(
//            step: step,
//            animation: .moveAndFade,
//            mainButtonType: .close,
//            backButtonVisible: false
//        )
//    }
}
