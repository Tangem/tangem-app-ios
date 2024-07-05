//
//  SendStepsManagerInputOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SendStepsManagerInput: AnyObject {
    var currentStep: any SendStep { get }
}

protocol SendStepsManagerOutput: AnyObject {
    func update(step: any SendStep, animation: SendView.StepAnimation)

    func update(mainButtonType: SendMainButtonType)
    func update(backButtonVisible: Bool)
}
