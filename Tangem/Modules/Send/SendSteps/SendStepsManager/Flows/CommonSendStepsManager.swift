//
//  CommonSendStepsManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 09.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class CommonSendStepsManager {
    private let destinationStep: SendDestinationStep
    private let amountStep: SendAmountStep
    private let feeStep: SendFeeStep
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    init(
        destinationStep: SendDestinationStep,
        amountStep: SendAmountStep,
        feeStep: SendFeeStep,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep
    ) {
        self.destinationStep = destinationStep
        self.amountStep = amountStep
        self.feeStep = feeStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep

        stack = [destinationStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last

        assert(last != nil, "Stack is empty")

        return last ?? initialState.step
    }

    private func getNextStep() -> (SendStep)? {
        switch currentStep().type {
        case .destination:
            return amountStep
        case .amount:
            return summaryStep
        case .fee, .summary, .finish:
            assertionFailure("There is no next step")
            return nil
        }
    }

    private func next(step: SendStep) {
        let isEditAction = stack.contains(where: { $0.type.isSummary })
        stack.append(step)

        switch step.type {
        case .summary:
            output?.update(state: .moveAndFade(step: step, action: .send))
        case .finish:
            output?.update(state: .moveAndFade(step: step, action: .close))
        case .amount where isEditAction,
             .destination where isEditAction,
             .fee where isEditAction:
            output?.update(state: .moveAndFade(step: step, action: .continue))
        case .amount, .destination, .fee:
            output?.update(state: .next(step: step))
        }
    }

    private func back() {
        stack.removeLast()
        let step = currentStep()

        switch step.type {
        case .summary:
            output?.update(state: .moveAndFade(step: step, action: .send))
        default:
            output?.update(state: .back(step: step))
        }
    }
}

// MARK: - SendStepsManager

extension CommonSendStepsManager: SendStepsManager {
    var initialState: SendStepsManagerViewState {
        .init(step: destinationStep, animation: .slideForward, mainButtonType: .next, backButtonVisible: false)
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

        guard currentStep().canBeClosed(continueAction: back) else {
            return
        }

        back()
    }
}

// MARK: - SendSummaryStepsRoutable

extension CommonSendStepsManager: SendSummaryStepsRoutable {
    func summaryStepRequestEditDestination() {
        guard case .summary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: destinationStep)
    }

    func summaryStepRequestEditAmount() {
        guard case .summary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: amountStep)
    }

    func summaryStepRequestEditFee() {
        guard case .summary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: feeStep)
    }
}

// MARK: - SendDestinationStepRoutable

extension CommonSendStepsManager: SendDestinationStepRoutable {
    func destinationStepFulfilled() {
        performNext()
    }
}
