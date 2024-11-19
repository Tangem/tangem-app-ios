//
//  CommonSellStepsManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 09.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class CommonSellStepsManager {
    private let feeStep: SendFeeStep
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    init(
        feeStep: SendFeeStep,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep
    ) {
        self.feeStep = feeStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep

        stack = [summaryStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last

        assert(last != nil, "Stack is empty")

        return last ?? initialState.step
    }

    private func next(step: SendStep) {
        let isEditAction = stack.contains(where: { $0.type.isSummary })
        stack.append(step)

        switch step.type {
        case .summary:
            output?.update(state: .init(step: step, action: .action))
        case .finish:
            output?.update(state: .init(step: step, action: .close))
        case .fee where isEditAction:
            output?.update(state: .init(step: step, action: .continue))
        case .amount, .destination, .fee, .validators, .onramp:
            assertionFailure("There is no next step")
        }
    }

    private func back() {
        stack.removeLast()
        let step = currentStep()

        switch step.type {
        case .summary:
            output?.update(state: .init(step: step, action: .action))
        default:
            output?.update(state: .init(step: step, action: .next))
        }
    }
}

// MARK: - SendStepsManager

extension CommonSellStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { false }

    var initialFlowActionType: SendFlowActionType { .send }

    var initialState: SendStepsManagerViewState {
        .init(step: summaryStep, action: .action, backButtonVisible: false)
    }

    var shouldShowDismissAlert: Bool {
        return true
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
        assert(stack.contains(where: { $0.type.isSummary }), "Continue is possible only after summary")

        back()
    }
}

// MARK: - SendSummaryStepsRoutable

extension CommonSellStepsManager: SendSummaryStepsRoutable {
    func summaryStepRequestEditDestination() {
        assertionFailure("This steps is not tappable in this flow")
    }

    func summaryStepRequestEditAmount() {
        assertionFailure("This steps is not tappable in this flow")
    }

    func summaryStepRequestEditValidators() {
        assertionFailure("This steps is not tappable in this flow")
    }

    func summaryStepRequestEditFee() {
        guard case .summary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: feeStep)
    }
}
