//
//  SendStepsManagerInputOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SendStepsManagerOutput: AnyObject {
    func update(state: SendStepsManagerViewState)
}

struct SendStepsManagerViewState {
    let step: SendStep
    let mainButtonType: SendMainButtonType
    let backButtonVisible: Bool

    static func next(step: SendStep) -> SendStepsManagerViewState {
        SendStepsManagerViewState(
            step: step,
            mainButtonType: .next,
            backButtonVisible: true
        )
    }

    static func back(step: SendStep) -> SendStepsManagerViewState {
        SendStepsManagerViewState(
            step: step,
            mainButtonType: .next,
            backButtonVisible: false
        )
    }

    static func moveAndFade(step: SendStep, action: SendMainButtonType) -> SendStepsManagerViewState {
        SendStepsManagerViewState(
            step: step,
            mainButtonType: action,
            backButtonVisible: false
        )
    }
}
