//
//  ExpressApproveViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 11.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import UIKit
import enum TangemSdk.TangemSdkError
import struct BlockchainSdk.Fee

final class ExpressApproveViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var subheader: String

    @Published var menuRowViewModel: DefaultMenuRowViewModel<ExpressApprovePolicy>?
    @Published var selectedAction: ExpressApprovePolicy
    @Published var feeRowViewModel: DefaultRowViewModel?

    @Published var isLoading = false
    @Published var mainButtonIsDisabled = false
    @Published var errorAlert: AlertBinder?

    // MARK: - Dependencies

    private let feeFormatter: FeeFormatter
    private let pendingTransactionRepository: ExpressPendingTransactionRepository
    private let logger: Logger
    private let expressInteractor: ExpressInteractor
    private weak var coordinator: ExpressApproveRoutable?

    private var didBecomeActiveNotificationCancellable: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(
        feeFormatter: FeeFormatter,
        pendingTransactionRepository: ExpressPendingTransactionRepository,
        logger: Logger,
        expressInteractor: ExpressInteractor,
        providerName: String,
        selectedPolicy: ExpressApprovePolicy,
        coordinator: ExpressApproveRoutable
    ) {
        self.feeFormatter = feeFormatter
        self.pendingTransactionRepository = pendingTransactionRepository
        self.logger = logger
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator

        let currencySymbol = expressInteractor.getSender().tokenItem.currencySymbol

        selectedAction = selectedPolicy
        subheader = Localization.givePermissionSwapSubtitle(providerName, currencySymbol)
        menuRowViewModel = .init(
            title: Localization.givePermissionRowsAmount(currencySymbol),
            actions: [.unlimited, .specified]
        )

        feeRowViewModel = DefaultRowViewModel(title: Localization.commonNetworkFeeTitle, detailsType: .none)
        updateView(for: expressInteractor.getState())
        bind()
    }

    func didTapInfoButton() {
        errorAlert = AlertBinder(
            title: Localization.swappingApproveInformationTitle,
            message: Localization.swappingApproveInformationText
        )
    }

    func didTapApprove() {
        sendApproveTransaction()
    }

    func didTapCancel() {
        Analytics.log(.swapButtonPermissionCancel)
        coordinator?.userDidCancel()
    }
}

// MARK: - Navigation

extension ExpressApproveViewModel {
    @MainActor
    func didSendApproveTransaction() {
        // We have to wait when the iOS close the nfc view that close this permission view
        didBecomeActiveNotificationCancellable = NotificationCenter
            .default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.coordinator?.didSendApproveTransaction()
            }
    }
}

// MARK: - Private

private extension ExpressApproveViewModel {
    func bind() {
        expressInteractor.state
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                viewModel.updateView(for: state)
            }
            .store(in: &bag)

        $selectedAction
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, policy in
                viewModel.expressInteractor.updateApprovePolicy(policy: policy)
            }
            .store(in: &bag)
    }

    func updateView(for state: ExpressInteractor.State) {
        switch state {
        case .permissionRequired(let state, _):
            updateFeeAmount(fees: state.fees)
            isLoading = false
            mainButtonIsDisabled = false
        case .loading:
            feeRowViewModel?.update(detailsType: .loader)
            isLoading = true
            mainButtonIsDisabled = false
        case .restriction(.requiredRefresh(let error), _):
            errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
            isLoading = false
            mainButtonIsDisabled = true
        default:
            AppLog.shared.debug("Wrong state for this view \(state)")
            isLoading = false
            mainButtonIsDisabled = true
        }
    }

    func updateFeeAmount(fees: [FeeOption: Fee]) {
        guard let fee = fees[expressInteractor.getFeeOption()] else {
            errorAlert = AlertBinder(
                title: Localization.commonError,
                message: ExpressInteractorError.feeNotFound.localizedDescription
            )

            return
        }

        let formatted = feeFormatter.format(
            fee: fee.amount.value,
            tokenItem: expressInteractor.getSender().feeTokenItem
        )

        feeRowViewModel?.update(detailsType: .text(formatted))
    }

    func setupExpressView() {
        runTask(in: self) { viewModel in
            let approvePolicy = await viewModel.expressInteractor.getApprovePolicy()
            await runOnMain {
                viewModel.selectedAction = approvePolicy
            }

            guard let provider = await viewModel.expressInteractor.getSelectedProvider()?.provider else {
                return
            }

            let currencySymbol = viewModel.expressInteractor.getSender().tokenItem.currencySymbol
            await runOnMain {
                viewModel.subheader = Localization.givePermissionSwapSubtitle(provider.name, currencySymbol)
            }
        }

        let currencySymbol = expressInteractor.getSender().tokenItem.currencySymbol
    }

    func sendApproveTransaction() {
        runTask(in: self) { viewModel in
            do {
                try await viewModel.expressInteractor.sendApproveTransaction()
                await viewModel.didSendApproveTransaction()
            } catch SendTransactionDispatcherResult.Error.userCancelled {
                // Do nothing
            } catch {
                viewModel.logger.error(error)
                await runOnMain {
                    viewModel.errorAlert = .init(title: Localization.commonError, message: error.localizedDescription)
                }
            }
        }
    }
}

extension ExpressApprovePolicy: DefaultMenuRowViewModelAction {
    public var id: Int { hashValue }

    public var title: String {
        switch self {
        case .specified:
            return Localization.givePermissionCurrentTransaction
        case .unlimited:
            return Localization.givePermissionUnlimited
        }
    }
}
