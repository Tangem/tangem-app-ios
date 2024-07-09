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

    private var stack: [SendStep] = [] {
        didSet {
            print("stack ->>", stack.map { $0.type })
        }
    }

//    private weak var input: SendStepsManagerInput?
    private weak var output: SendStepsManagerOutput?

    private var bag: Set<AnyCancellable> = []

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

    private func open(step: SendStep) {
        let isEditAction = stack.contains(where: { $0.type == .summary })
        stack.append(step)

        switch step.type {
        case .summary:
            output?.update(state: .moveAndFade(step: step, action: .send))
        case .finish:
            output?.update(state: .moveAndFade(step: step, action: .close))
        default:
            if isEditAction {
                output?.update(state: .moveAndFade(step: step, action: .continue))
            } else {
                output?.update(state: .next(step: step))
            }
        }
    }

    private func remove() -> SendStep {
        stack.removeLast()

        return currentStep()
    }

    private func currentStep() -> SendStep {
        let last = stack.last

        assert(last != nil, "Stack is empty")

        return last ?? firstStep
    }

//    private func getPreviousStep() -> (SendStep)? {
//        switch input?.currentStep.type {
//        case .none:
//            return destinationStep
//        case .destination:
//            return amountStep
//        case .amount:
//            return destinationStep
//        case .fee, .summary, .finish:
//            assertionFailure("There is no previous step")
//            return nil
//        }
//    }

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

    //    private func openStep(_ step: SendStep, animation: SendView.StepAnimation) {
    //        output?.update(animation: animation)
    //        output?.update(step: step, animation: animation)
    //    }

    //    private func openStep(_ step: SendStep, stepAnimation: SendView.StepAnimation, checkCustomFee: Bool = true, updateFee: Bool) {
    //        let openStepAfterDelay = { [weak self] in
    //            // Slight delay is needed, otherwise the animation of the keyboard will interfere with the page change
    //            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    //                self?.openStep(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee, updateFee: false)
    //            }
    //        }

    //        if updateFee {
    //            self.updateFee()
    //            keyboardVisibilityService.hideKeyboard(completion: openStepAfterDelay)
    //            return
    //        }
    //
    //        if keyboardVisibilityService.keyboardVisible, !step.opensKeyboardByDefault {
    //            keyboardVisibilityService.hideKeyboard(completion: openStepAfterDelay)
    //            return
    //        }

    //        if case .summary = step {
    //            if showSummaryStepAlertIfNeeded(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee) {
    //                return
    //            }

    //            didReachSummaryScreen = true

    //            sendSummaryViewModel.setupAnimations(previousStep: self.step)
    //        }

    // Gotta give some time to update animation variable
    //        self.stepAnimation = stepAnimation

    //        mainButtonType = self.mainButtonType(for: step)
    //
    //        DispatchQueue.main.async {
    //            self.showBackButton = self.previousStep(before: step) != nil && !self.didReachSummaryScreen
    //            self.showTransactionButtons = self.sendModel.transactionURL != nil
    //            self.step = step
    //            self.transactionDescriptionIsVisisble = step == .summary
    //        }
    //    }
}

// TODO: Update fee
// TODO: Update main button
// TODO: Show alert fee

// MARK: - SendStepsManager

extension CommonSendStepsManager: SendStepsManager {
    var firstStep: SendStep { destinationStep }

    func setup(input _: SendStepsManagerInput, output: SendStepsManagerOutput) {
//        self.input = input
        self.output = output
    }

    func performBack() {
        output?.update(state: .back(step: remove()))
    }

    func performNext() {
        guard let next = getNextStep() else {
            return
        }

        func openNext() {
            keyboardVisibilityService.hideKeyboard(completion: {})
            open(step: next)
        }

        guard currentStep().canBeClosed(continueAction: openNext) else {
            return
        }

        openNext()
    }

    func performFinish() {
        open(step: finishStep)
    }

    func performContinue() {
        assert(stack.contains(where: { $0.type == .summary }), "Continue is possible only after summary")

        let summary = remove()
        assert(summary.type == .summary, "Continue is possible only after summary")

        keyboardVisibilityService.hideKeyboard {}
        output?.update(state: .moveAndFade(step: summary, action: .send))
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
            open(step: destinationStep)
        case .amount:
            open(step: amountStep)
        case .fee:
            open(step: feeStep)
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
