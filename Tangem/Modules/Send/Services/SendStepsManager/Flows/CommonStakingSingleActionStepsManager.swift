//
//  CommonStakingSingleActionStepsManager.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 26.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

class CommonStakingSingleActionStepsManager {
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep
    private let action: UnstakingModel.Action

    private var stack: [SendStep]
    private var bag: Set<AnyCancellable> = []
    private weak var output: SendStepsManagerOutput?

    init(
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep,
        action: UnstakingModel.Action
    ) {
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.action = action

        stack = [summaryStep]
    }

    private func next(step: SendStep) {
        stack.append(step)

        switch step.type {
        case .finish:
            output?.update(state: .init(step: step, action: .close))
        case .amount, .destination, .fee, .summary, .validators, .onramp:
            assertionFailure("There is no next step")
        }
    }
}

// MARK: - SendStepsManager

extension CommonStakingSingleActionStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { false }

    var initialFlowActionType: SendFlowActionType {
        switch action.type {
        case .unstake:
            return .unstake
        case .pending(.withdraw):
            return .withdraw
        case .pending(.claimRewards):
            return .claimRewards
        case .pending(.restakeRewards):
            return .restakeRewards
        case .pending(.voteLocked):
            return .stake
        case .pending(.unlockLocked):
            return .unlockLocked
        case .stake, .pending(.stake):
            assertionFailure("Doesn't support in UnstakingFlow")
            return .unstake
        case .pending(.restake):
            return .restake
        case .pending(.claimUnstaked):
            return .claimUnstaked
        }
    }

    var initialState: SendStepsManagerViewState {
        .init(step: summaryStep, action: .action, backButtonVisible: false)
    }

    var shouldShowDismissAlert: Bool {
        return false
    }

    func set(output: SendStepsManagerOutput) {
        self.output = output
    }

    func performBack() {
        assertionFailure("There's not back action in this flow")
    }

    func performNext() {
        assertionFailure("There's not next action in this flow")
    }

    func performFinish() {
        next(step: finishStep)
    }

    func performContinue() {
        assertionFailure("There's not continue action in this flow")
    }
}
