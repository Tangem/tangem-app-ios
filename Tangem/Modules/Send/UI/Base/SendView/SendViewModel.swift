//
//  SendViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 06.06.2024.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdk
import TangemExpress

protocol SendViewAlertPresenter: AnyObject {
    func showAlert(_ alert: AlertBinder)
}

final class SendViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var step: SendStep
    @Published var mainButtonType: SendMainButtonType
    @Published var flowActionType: SendFlowActionType
    @Published var showBackButton = false
    @Published var isKeyboardActive: Bool = false

    @Published var transactionURL: URL?

    @Published var closeButtonDisabled = false
    @Published var isUserInteractionDisabled = false
    @Published var mainButtonLoading: Bool = false
    @Published var actionIsAvailable: Bool = false

    @Published var alert: AlertBinder?

    var title: String? { step.title }
    var subtitle: String? { step.subtitle }

    var closeButtonColor: Color {
        closeButtonDisabled ? Colors.Text.disabled : Colors.Text.primary1
    }

    var shouldShowDismissAlert: Bool {
        stepsManager.shouldShowDismissAlert
    }

    private let interactor: SendBaseInteractor
    private let stepsManager: SendStepsManager
    private let userWalletModel: UserWalletModel
    private let alertBuilder: SendAlertBuilder
    private let dataBuilder: SendBaseDataBuilder
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    private weak var coordinator: SendRoutable?

    private var bag: Set<AnyCancellable> = []

    private var sendTask: Task<Void, Never>?
    private var isValidSubscription: AnyCancellable?

    init(
        interactor: SendBaseInteractor,
        stepsManager: SendStepsManager,
        userWalletModel: UserWalletModel,
        alertBuilder: SendAlertBuilder,
        dataBuilder: SendBaseDataBuilder,
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        coordinator: SendRoutable
    ) {
        self.interactor = interactor
        self.stepsManager = stepsManager
        self.userWalletModel = userWalletModel
        self.alertBuilder = alertBuilder
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.dataBuilder = dataBuilder
        self.coordinator = coordinator

        step = stepsManager.initialState.step
        mainButtonType = stepsManager.initialState.action
        flowActionType = stepsManager.initialFlowActionType
        isKeyboardActive = stepsManager.initialKeyboardState

        bind()
        bind(step: stepsManager.initialState.step)
    }

    func userDidTapActionButton() {
        switch mainButtonType {
        case .next:
            stepsManager.performNext()
            if flowActionType == .stake {
                Analytics.log(.stakingButtonNext)
            }
        case .continue:
            stepsManager.performContinue()
        case .action where flowActionType == .approve:
            performApprove()
        case .action:
            performAction()
        case .close:
            coordinator?.dismiss()
        }
    }

    func userDidTapBackButton() {
        stepsManager.performBack()
    }

    func onAppear(newStep: any SendStep) {
        switch (step.type, newStep.type) {
        case (_, .summary):
            isKeyboardActive = false
        default:
            break
        }
    }

    func onDisappear(oldStep: any SendStep) {
        oldStep.sendStepViewAnimatable.viewDidChangeVisibilityState(.disappeared)
        step.sendStepViewAnimatable.viewDidChangeVisibilityState(.appeared)

        switch (oldStep.type, step.type) {
        // It's possible to the destination step
        // if the destination's TextField will be support @FocusState
        // case (_, .destination):
        //    isKeyboardActive = true
        case (_, .amount):
            isKeyboardActive = true
        case (_, .onramp):
            isKeyboardActive = true
        default:
            break
        }
    }

    func dismiss() {
        let source = step.type.analyticsSourceParameterValue
        if flowActionType == .send {
            Analytics.log(.sendButtonClose, params: [
                .source: source,
                .fromSummary: .affirmativeOrNegative(for: step.type.isSummary),
                .valid: .affirmativeOrNegative(for: actionIsAvailable),
            ])
        } else {
            Analytics.log(event: .stakingButtonCancel, params: [
                .source: source.rawValue,
                .token: tokenItem.currencySymbol,
            ])
        }

        if shouldShowDismissAlert {
            alert = alertBuilder.makeDismissAlert { [weak self] in
                self?.coordinator?.dismiss()
            }
        } else {
            coordinator?.dismiss()
        }
    }

    func share(url: URL) {
        if flowActionType == .send {
            Analytics.log(.sendButtonShare)
        } else {
            Analytics.log(.stakingButtonShare)
        }
        coordinator?.openShareSheet(url: url)
    }

    func explore(url: URL) {
        if flowActionType == .send {
            Analytics.log(.sendButtonExplore)
        } else {
            Analytics.log(.stakingButtonExplore)
        }
        coordinator?.openExplorer(url: url)
    }
}

// MARK: - Private

private extension SendViewModel {
    func performApprove() {
        do {
            let (settings, approveViewModelInput) = try dataBuilder.makeDataForExpressApproveViewModel()
            coordinator?.openApproveView(settings: settings, approveViewModelInput: approveViewModelInput)
        } catch {
            alert = error.alertBinder
        }
    }

    func performAction() {
        sendTask?.cancel()
        sendTask = runTask(in: self) { viewModel in
            do {
                let result = try await viewModel.interactor.action()
                await viewModel.proceed(result: result)
            } catch let error as TransactionDispatcherResult.Error {
                // The demo alert doesn't show without delay
                try? await Task.sleep(seconds: 1)
                await viewModel.proceed(error: error)
            } catch _ as CancellationError {
                // Do nothing
            } catch {
                AppLog.shared.error(error)
                await runOnMain { viewModel.showAlert(error.alertBinder) }
            }
        }
    }

    @MainActor
    func proceed(result: TransactionDispatcherResult) {
        transactionURL = result.url
        stepsManager.performFinish()
    }

    @MainActor
    func proceed(error: TransactionDispatcherResult.Error) {
        switch error {
        case .userCancelled, .transactionNotFound:
            break
        case .informationRelevanceServiceError:
            alert = alertBuilder.makeFeeRetryAlert { [weak self] in
                self?.performAction()
            }
        case .informationRelevanceServiceFeeWasIncreased:
            alert = AlertBuilder.makeOkGotItAlert(message: Localization.sendNotificationHighFeeTitle)
        case .sendTxError(let transaction, let sendTxError):
            alert = alertBuilder.makeTransactionFailedAlert(sendTxError: sendTxError) { [weak self] in
                self?.openMail(transaction: transaction, error: sendTxError)
            }
        case .loadTransactionInfo(let error):
            alert = alertBuilder.makeTransactionFailedAlert(sendTxError: .init(error: error)) { [weak self] in
                self?.openMail(error: error)
            }
        case .demoAlert:
            alert = AlertBuilder.makeDemoAlert(Localization.alertDemoFeatureDisabled) { [weak self] in
                self?.coordinator?.dismiss()
            }
        }
    }

    func openMail(error: Error) {
        Analytics.log(.requestSupport, params: [.source: .transactionSourceSend])

        do {
            let (emailDataCollector, recipient) = try dataBuilder.makeMailData(stakingRequestError: error)
            coordinator?.openMail(with: emailDataCollector, recipient: recipient)
        } catch {
            alert = error.alertBinder
        }
    }

    func openMail(transaction: SendTransactionType, error: SendTxError) {
        Analytics.log(.requestSupport, params: [.source: .transactionSourceSend])

        let (emailDataCollector, recipient) = dataBuilder.makeMailData(transaction: transaction, error: error)
        coordinator?.openMail(with: emailDataCollector, recipient: recipient)
    }

    func bind(step: SendStep) {
        isValidSubscription = step.isValidPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.actionIsAvailable, on: self, ownership: .weak)
    }

    func bind() {
        interactor.actionInProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: \.closeButtonDisabled, on: self, ownership: .weak)
            .store(in: &bag)

        interactor.actionInProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: \.isUserInteractionDisabled, on: self, ownership: .weak)
            .store(in: &bag)

        interactor.actionInProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: \.mainButtonLoading, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

// MARK: - SendModelRoutable

extension SendViewModel: SendModelRoutable {
    func openNetworkCurrency() {
        let walletModels = userWalletModel.walletModelsManager.walletModels
        guard let feeCurrencyWalletModel = walletModels.first(where: { $0.tokenItem == feeTokenItem }) else {
            assertionFailure("Network currency WalletModel not found")
            return
        }

        coordinator?.openFeeCurrency(for: feeCurrencyWalletModel, userWalletModel: userWalletModel)
    }
}

// MARK: - SendModelRoutable

extension SendViewModel: OnrampModelRoutable {
    func openOnrampCountryBottomSheet(country: OnrampCountry) {
        // TODO: https://tangem.atlassian.net/browse/IOS-8268
    }
}

// MARK: - SendViewAlertPresenter

extension SendViewModel: SendViewAlertPresenter {
    func showAlert(_ alert: AlertBinder) {
        self.alert = alert
    }
}

// MARK: - SendStepsManagerOutput

extension SendViewModel: SendStepsManagerOutput {
    func update(state: SendStepsManagerViewState) {
        step.willDisappear(next: state.step)
        step.sendStepViewAnimatable.viewDidChangeVisibilityState(
            .disappearing(nextStep: state.step.type)
        )

        state.step.willAppear(previous: step)
        state.step.sendStepViewAnimatable.viewDidChangeVisibilityState(
            .appearing(previousStep: step.type)
        )

        mainButtonType = state.action
        showBackButton = state.backButtonVisible

        // Give some time to update `transitions`
        DispatchQueue.main.async {
            self.step = state.step
            self.bind(step: state.step)
        }
    }

    func update(flowActionType: SendFlowActionType) {
        DispatchQueue.main.async {
            self.flowActionType = flowActionType
        }
    }
}
