//
//  SendStepsManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendStepsManager {
    var initialKeyboardState: Bool { get }
    var initialFlowActionType: SendFlowActionType { get }
    var initialState: SendStepsManagerViewState { get }

    var shouldShowDismissAlert: Bool { get }

    func performNext()
    func performBack()

    func performContinue()
    func performFinish()

    func set(output: SendStepsManagerOutput)
}
