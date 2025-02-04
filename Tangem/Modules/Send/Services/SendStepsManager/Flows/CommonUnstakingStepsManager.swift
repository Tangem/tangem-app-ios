//
//  CommonUnstakingStepsManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

class CommonUnstakingStepsManager {
    private let amountStep: SendAmountStep
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep
    private let action: UnstakingModel.Action
    private let supportsPartialUnstake: Bool

    private var stack: [SendStep]
    private var bag: Set<AnyCancellable> = []
    private weak var output: SendStepsManagerOutput?

    init(
        amountStep: SendAmountStep,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep,
        action: UnstakingModel.Action,
        supportsPartialUnstake: Bool
    ) {
        self.amountStep = amountStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.action = action
        self.supportsPartialUnstake = supportsPartialUnstake

        stack = [supportsPartialUnstake ? amountStep : summaryStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last

        assert(last != nil, "Stack is empty")

        return last ?? initialState.step
    }

    private func getNextStep() -> (SendStep)? {
        switch currentStep().type {
        case .amount:
            return summaryStep
        case .destination, .fee, .validators, .summary, .finish, .onramp:
            assertionFailure("There is no next step")
            return nil
        }
    }

    private func next(step: SendStep) {
        let isEditAction = stack.contains(where: { $0.type.isSummary })
        stack.append(step)

        switch step.type {
        case .amount where isEditAction:
            output?.update(state: .init(step: step, action: .continue))
        case .finish:
            output?.update(state: .init(step: step, action: .close))
        case .summary:
            output?.update(state: .init(step: step, action: .action))
        case .amount, .destination, .fee, .validators, .onramp:
            assertionFailure("There is no next step")
        }
    }

    private func back() {
        guard !stack.isEmpty else {
            // Ignore double click
            return
        }

        stack.removeLast()
        let step = currentStep()

        switch step.type {
        case .summary:
            output?.update(state: .init(step: step, action: .action))
        default:
            assertionFailure("There is no back step")
        }
    }
}

// MARK: - SendStepsManager

extension CommonUnstakingStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { true }

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
        case .pending(.voteLocked), .pending(.restake):
            return .stake
        case .pending(.unlockLocked):
            return .unlockLocked
        case .pending(.claimUnstaked):
            return .claimUnstaked
        case .stake:
            assertionFailure("Doesn't support in UnstakingFlow")
            return .unstake
        }
    }

    var initialState: SendStepsManagerViewState {
        if supportsPartialUnstake {
            .init(step: amountStep, action: .next, backButtonVisible: false)
        } else {
            .init(step: summaryStep, action: .action, backButtonVisible: false)
        }
    }

    var shouldShowDismissAlert: Bool {
        stack.contains(where: { $0.type.isSummary })
    }

    func set(output: SendStepsManagerOutput) {
        self.output = output
    }

    func performBack() {
        back()
    }

    func performNext() {
        guard let step = getNextStep() else {
            return
        }

        func openNext() {
            next(step: step)
        }

        guard currentStep().canBeClosed(continueAction: openNext) else {
            return
        }

        openNext()
    }

    func performFinish() {
        next(step: finishStep)
    }

    func performContinue() {
        assert(stack.contains(where: { $0.type.isSummary }), "Continue is possible only after summary")

        back()
    }
}

// MARK: - SendSummaryStepsRoutable

extension CommonUnstakingStepsManager: SendSummaryStepsRoutable {
    func summaryStepRequestEditValidators() {
        assertionFailure("We can't edit validators in unstaking flow")
    }

    func summaryStepRequestEditAmount() {
        guard case .summary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: amountStep)
    }

    func summaryStepRequestEditDestination() {
        assertionFailure("This steps is not tappable in this flow")
    }

    func summaryStepRequestEditFee() {
        assertionFailure("This steps is not tappable in this flow")
    }
}
