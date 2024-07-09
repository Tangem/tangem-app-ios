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
    var firstStep: SendStep { get }

    func performNext()
    func performBack()

    func performContinue()
    func performFinish()

    func setup(input: SendStepsManagerInput, output: SendStepsManagerOutput)
}

class CommonSendStepsManager {
    private let keyboardVisibilityService: KeyboardVisibilityService
    private let destinationStep: SendDestinationStep
    private let amountStep: SendAmountStep
    private let feeStep: SendFeeStep
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep

    private var stack: [SendStep] {
        didSet {
            print("stack ->>", stack.map { $0.type })
        }
    }

//    private weak var input: SendStepsManagerInput?
    private weak var output: SendStepsManagerOutput?

    init(
        keyboardVisibilityService: KeyboardVisibilityService,
        destinationStep: SendDestinationStep,
        amountStep: SendAmountStep,
        feeStep: SendFeeStep,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep
    ) {
        self.keyboardVisibilityService = keyboardVisibilityService
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

        return last ?? firstStep
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
        let isEditAction = stack.contains(where: { $0.type == .summary })
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
    var firstStep: SendStep { destinationStep }

    func setup(input _: SendStepsManagerInput, output: SendStepsManagerOutput) {
//        self.input = input
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
        assert(stack.contains(where: { $0.type == .summary }), "Continue is possible only after summary")

        back()
    }
}

// MARK: - SendSummaryRoutable

extension CommonSendStepsManager: SendSummaryRoutable {
    func openStep(_ step: SendStepType) {
        guard case .summary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        if let auxiliaryViewAnimatable = auxiliaryViewAnimatable(step) {
            auxiliaryViewAnimatable.setAnimatingAuxiliaryViewsOnAppear()
        }

        switch step {
        case .destination:
            next(step: destinationStep)
        case .amount:
            next(step: amountStep)
        case .fee:
            next(step: feeStep)
        case .summary, .finish:
            assertionFailure("Not implemented")
        }
    }

    private func auxiliaryViewAnimatable(_ step: SendStepType) -> AuxiliaryViewAnimatable? {
        switch step {
        case .destination:
            return destinationStep.auxiliaryViewAnimatable
        case .amount:
            return amountStep.auxiliaryViewAnimatable
        case .fee:
            return feeStep.auxiliaryViewAnimatable
        case .summary, .finish:
            return nil
        }
    }
}

// MARK: - SendDestinationStepRoutable

extension CommonSendStepsManager: SendDestinationStepRoutable {
    func destinationStepFulfilled() {
        performNext()
    }
}
