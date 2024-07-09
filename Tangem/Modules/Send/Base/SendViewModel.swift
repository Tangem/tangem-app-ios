//
//  SendViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 06.06.2024.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class SendViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var stepAnimation: SendView.StepAnimation
    @Published var step: SendStep {
        willSet {
            step.willDisappear(next: newValue)
            newValue.willAppear(previous: step)
        } didSet {
            bind(step: step)
        }
    }

    @Published var mainButtonType: SendMainButtonType
    @Published var showBackButton = false

    @Published var transactionURL: URL?

    @Published var closeButtonDisabled = false
    @Published var isUserInteractionDisabled = false
    @Published var mainButtonLoading: Bool = false
    @Published var mainButtonDisabled: Bool = false

    @Published var alert: AlertBinder?

    var title: String? { step.title }
    var subtitle: String? { step.subtitle }

    var closeButtonColor: Color {
        closeButtonDisabled ? Colors.Text.disabled : Colors.Text.primary1
    }

    var shouldShowDismissAlert: Bool {
        if case .finish = step.type {
            return false
        }

        return mainButtonType == .send || mainButtonType == .continue
    }

    private let interactor: SendBaseInteractor
    private let stepsManager: SendStepsManager
    private weak var router: SendRoutable?

    private var bag: Set<AnyCancellable> = []
    private var isValidSubscription: AnyCancellable?

//    private var currentPageAnimating: Bool = false
//    private var didReachSummaryScreen: Bool = false

    init(
        interactor: SendBaseInteractor,
        stepsManager: SendStepsManager,
        router: SendRoutable
    ) {
        self.interactor = interactor
        self.stepsManager = stepsManager
        self.router = router

        step = stepsManager.firstStep
//        didReachSummaryScreen = stepsManager.firstStep.type == .summary
        stepAnimation = .slideForward
        mainButtonType = .next

        bind()
        bind(step: stepsManager.firstStep)
    }

    func onCurrentPageAppear() {
        step.didAppear()
//        currentPageAnimating = true
    }

    func onCurrentPageDisappear() {
        step.didDisappear()
//        currentPageAnimating = false
    }

    func userDidTapActionButton() {
        switch mainButtonType {
        case .next:
            stepsManager.performNext()
        case .continue:
            stepsManager.performContinue()
        case .send:
            performSend()
        case .close:
            router?.dismiss()
        }
    }

    func userDidTapBackButton() {
        stepsManager.performBack()
    }

    func dismiss() {
        Analytics.log(.sendButtonClose, params: [
            .source: step.type.analyticsSourceParameterValue,
            .fromSummary: .affirmativeOrNegative(for: step.type == .summary),
            .valid: .affirmativeOrNegative(for: !mainButtonDisabled),
        ])

        if shouldShowDismissAlert {
            alert = SendAlertBuilder.makeDismissAlert { [weak self] in
                self?.router?.dismiss()
            }
        } else {
            router?.dismiss()
        }
    }

    func share(url: URL) {
        Analytics.log(.sendButtonShare)
        router?.openShareSheet(url: url)
    }

    func explore(url: URL) {
        Analytics.log(.sendButtonExplore)
        router?.openExplorer(url: url)
    }
}

// MARK: - Private

private extension SendViewModel {
    private func performSend() {
        interactor.send()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, result in
                viewModel.transactionURL = result.url
            }
            .store(in: &bag)
    }

    private func bind(step: SendStep) {
//        didReachSummaryScreen = step.type == .summary

        isValidSubscription = step.isValidPublisher
            .print("isValidPublisher ->> step \(step.type)")
            .map { !$0 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.mainButtonDisabled, on: self, ownership: .weak)
    }

    private func bind() {
        interactor.isLoading
            .assign(to: \.closeButtonDisabled, on: self, ownership: .weak)
            .store(in: &bag)

        interactor.isLoading
            .assign(to: \.mainButtonLoading, on: self, ownership: .weak)
            .store(in: &bag)

        interactor.isLoading
            .assign(to: \.isUserInteractionDisabled, on: self, ownership: .weak)
            .store(in: &bag)

        /*
         interactor
         .performNext
         .withWeakCaptureOf(self)
         .receive(on: DispatchQueue.main)
         .sink { viewModel, _ in
         viewModel.stepsManager.performNext()
         }
         .store(in: &bag)
         */
    }
}

// MARK: - SendModelUIDelegate

extension SendViewModel: SendModelUIDelegate {
    func showAlert(_ alert: AlertBinder) {
        self.alert = alert
    }
}

// MARK: - SendStepsManagerInput

extension SendViewModel: SendStepsManagerInput {
//    var currentStep: SendStep {
//        return step
//    }
}

// MARK: - SendStepsManagerOutput

extension SendViewModel: SendStepsManagerOutput {
    func update(state: SendStepsManagerViewState) {
        stepAnimation = state.animation

        DispatchQueue.main.async {
            self.step = state.step
            self.mainButtonType = state.mainButtonType
            self.showBackButton = state.backButtonVisible
        }
    }
}
