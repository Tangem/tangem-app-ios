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
    var firstStep: any SendStep { get }

    func performNext()
    func performBack()

    func performSummary()
    func performFinish()

    func setup(input: SendStepsManagerInput, output: SendStepsManagerOutput)
}

class CommonSendStepsManager {
    private let destinationStep: SendDestinationStep
    private let amountStep: SendAmountStep
    private let feeStep: SendFeeStep
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep

    private weak var input: SendStepsManagerInput?
    private weak var output: SendStepsManagerOutput?

    private var bag: Set<AnyCancellable> = []

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
    }

    private func getPreviousStep() -> (any SendStep)? {
        switch input?.currentStep.type {
        case .none:
            return destinationStep
        case .destination:
            return amountStep
        case .amount:
            return destinationStep
        case .fee, .summary, .finish:
            assertionFailure("There is no previous step")
            return nil
        }
    }

    private func getNextStep() -> (any SendStep)? {
        switch input?.currentStep.type {
        case .none:
            return destinationStep
        case .destination:
            return amountStep
        case .amount:
            return summaryStep
        case .fee, .summary, .finish:
            assertionFailure("There is no next step")
            return nil
        }
    }

    //    private func openStep(_ step: any SendStep, animation: SendView.StepAnimation) {
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
    var firstStep: any SendStep { destinationStep }

    func setup(input: SendStepsManagerInput, output: SendStepsManagerOutput) {
        self.input = input
        self.output = output
    }

    func performBack() {
        guard let previousStep = getPreviousStep() else {
            assertionFailure("Invalid step logic -- back")
            return
        }

        output?.update(step: previousStep, animation: .slideBackward)
    }

    func performNext() {
        guard let input, let next = getNextStep() else {
            return
        }

        func openNext() {
            switch next.type {
            case .destination, .amount, .fee, .finish:
                output?.update(step: next, animation: .slideForward)
                output?.update(mainButtonType: .next)
            case .summary:
                output?.update(step: next, animation: .moveAndFade)
                output?.update(mainButtonType: .send)
            }
        }

        guard input.currentStep.canBeClosed(continueAction: openNext) else {
            return
        }

        openNext()
    }

    func performFinish() {
        output?.update(step: finishStep, animation: .moveAndFade)
    }

    func performSummary() {
        output?.update(step: summaryStep, animation: .moveAndFade)
    }
}

// MARK: - SendSummaryRoutable

extension CommonSendStepsManager: SendSummaryRoutable {
    func openStep(_ step: SendStepType) {
        guard case .summary = input?.currentStep.type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        if let auxiliaryViewAnimatable = auxiliaryViewAnimatable(step) {
            auxiliaryViewAnimatable.setAnimatingAuxiliaryViewsOnAppear()
        }

        switch step {
        case .destination:
            output?.update(step: destinationStep, animation: .moveAndFade)
        case .amount:
            output?.update(step: amountStep, animation: .moveAndFade)
        case .fee:
            output?.update(step: feeStep, animation: .moveAndFade)
        case .summary:
            output?.update(step: summaryStep, animation: .moveAndFade)
        case .finish:
            output?.update(step: finishStep, animation: .moveAndFade)
        }
    }

    private func auxiliaryViewAnimatable(_ step: SendStepType) -> AuxiliaryViewAnimatable? {
        switch step {
        case .destination:
            return destinationStep.viewModel
        case .amount:
            return amountStep.viewModel
        case .fee:
            return feeStep.viewModel
        case .summary:
            return nil
        case .finish:
            return nil
        }
    }
}
