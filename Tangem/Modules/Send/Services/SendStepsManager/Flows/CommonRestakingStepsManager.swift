//
//  CommonRestakingStepsManager 2.swift
//  TangemApp
//
//  Created by Dmitry Fedorov on 30.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//
import Combine
import TangemStaking

class CommonRestakingStepsManager {
    private let validatorsStep: StakingValidatorsStep
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep
    private let action: RestakingModel.Action

    private var stack: [SendStep]
    private var bag: Set<AnyCancellable> = []
    private weak var output: SendStepsManagerOutput?

    init(
        validatorsStep: StakingValidatorsStep,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep,
        action: UnstakingModel.Action
    ) {
        self.validatorsStep = validatorsStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.action = action

        stack = [summaryStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last

        assert(last != nil, "Stack is empty")

        return last ?? initialState.step
    }

    private func next(step: SendStep) {
        stack.append(step)

        switch step.type {
        case .summary:
            output?.update(state: .init(step: step, action: .action))
        case .finish:
            output?.update(state: .init(step: step, action: .close))
        case .validators:
            output?.update(state: .init(step: step, action: .continue))
        case .amount, .destination, .fee, .onramp:
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
            assertionFailure("There is no back step")
        }
    }
}

// MARK: - SendStepsManager

extension CommonRestakingStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { false }

    var initialFlowActionType: SendFlowActionType {
        .voteLocked
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
        assert(stack.contains(where: { $0.type.isSummary }), "Continue is possible only after summary")

        back()
    }
}

// MARK: - SendSummaryStepsRoutable

extension CommonRestakingStepsManager: SendSummaryStepsRoutable {
    func summaryStepRequestEditValidators() {
        guard case .summary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: validatorsStep)
    }

    func summaryStepRequestEditAmount() {
        assertionFailure("This steps is not tappable in this flow")
    }

    func summaryStepRequestEditDestination() {
        assertionFailure("This steps is not tappable in this flow")
    }

    func summaryStepRequestEditFee() {
        assertionFailure("This steps is not tappable in this flow")
    }
}
