//
//  SwappingApproveViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 11.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemSwapping
import UIKit
import enum TangemSdk.TangemSdkError
import struct BlockchainSdk.Fee

final class SwappingApproveViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var menuRowViewModel: DefaultMenuRowViewModel<SwappingApprovePolicy>?
    @Published var selectedAction: SwappingApprovePolicy
    @Published var feeRowViewModel: DefaultRowViewModel?

    @Published var isLoading = false
    @Published var mainButtonIsDisabled = false
    @Published var errorAlert: AlertBinder?

    var subheader: String {
        if FeatureProvider.isAvailable(.express) {
            let currencySymbol = expressInteractor.getSender().tokenItem.currencySymbol
            return Localization.swappingPermissionSubheader(currencySymbol)
        }

        return Localization.swappingPermissionSubheader(swappingInteractor.getSwappingItems().source.symbol)
    }

    // MARK: - Dependencies

    // Old
    private let transactionSender: SwappingTransactionSender!
    private let fiatRatesProvider: FiatRatesProviding!
    private unowned let swappingInteractor: SwappingInteractor!

    // New
    private let swappingFeeFormatter: SwappingFeeFormatter
    private let pendingTransactionRepository: ExpressPendingTransactionRepository!
    private let logger: SwappingLogger
    private unowned let expressInteractor: ExpressInteractor!
    private unowned let coordinator: SwappingApproveRoutable

    private var didBecomeActiveNotificationCancellable: AnyCancellable?
    private var bag: Set<AnyCancellable> = []
    private var transactionData: SwappingTransactionData? {
        guard case .available(let model) = swappingInteractor.getAvailabilityState() else {
            AppLog.shared.debug("TransactionData for approve isn't found")
            return nil
        }

        return model.transactionData
    }

    init(
        transactionSender: SwappingTransactionSender?,
        fiatRatesProvider: FiatRatesProviding?,
        swappingInteractor: SwappingInteractor?,
        swappingFeeFormatter: SwappingFeeFormatter,
        pendingTransactionRepository: ExpressPendingTransactionRepository?,
        logger: SwappingLogger,
        expressInteractor: ExpressInteractor?,
        coordinator: SwappingApproveRoutable
    ) {
        self.transactionSender = transactionSender
        self.swappingInteractor = swappingInteractor
        self.fiatRatesProvider = fiatRatesProvider
        self.swappingFeeFormatter = swappingFeeFormatter
        self.pendingTransactionRepository = pendingTransactionRepository
        self.logger = logger
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator

        if FeatureProvider.isAvailable(.express) {
            selectedAction = expressInteractor!.getApprovePolicy()
            setupExpressView()
        } else {
            selectedAction = swappingInteractor!.getSwappingApprovePolicy()
            setupView()
        }

        bind()
    }

    func didTapInfoButton() {
        errorAlert = AlertBinder(
            title: Localization.swappingApproveInformationTitle,
            message: Localization.swappingApproveInformationText
        )
    }

    func didTapApprove() {
        if FeatureProvider.isAvailable(.express) {
            sendApproveTransaction()
        } else {
            guard let data = transactionData else {
                AppLog.shared.debug("TransactionData for approve isn't found")
                return
            }

            Analytics.log(
                event: .swapButtonPermissionApprove,
                params: [
                    .sendToken: data.sourceCurrency.symbol,
                    .receiveToken: data.destinationCurrency.symbol,
                ]
            )

            runTask(in: self) { root in
                do {
                    _ = try await root.transactionSender.sendTransaction(data)
                    root.swappingInteractor.didSendApproveTransaction(swappingTxData: data)
                    await root.didSendApproveTransaction()
                } catch TangemSdkError.userCancelled {
                    // Do nothing
                } catch {
                    await runOnMain {
                        root.errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
                    }
                }
            }
        }
    }

    func didTapCancel() {
        Analytics.log(.swapButtonPermissionCancel)
        coordinator.userDidCancel()
    }
}

// MARK: - Navigation

extension SwappingApproveViewModel {
    @MainActor
    func didSendApproveTransaction() {
        // We have to wait when the iOS close the nfc view that close this permission view
        didBecomeActiveNotificationCancellable = NotificationCenter
            .default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.coordinator.didSendApproveTransaction()
            }
    }
}

// MARK: - Private

private extension SwappingApproveViewModel {
    func bind() {
        if FeatureProvider.isAvailable(.express) {
            expressInteractor.state
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    self?.updateView(for: state)
                }
                .store(in: &bag)

            $selectedAction
                .dropFirst()
                .sink { [weak self] policy in
                    self?.expressInteractor.updateApprovePolicy(policy: policy)
                }
                .store(in: &bag)
        } else {
            swappingInteractor.state
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    self?.updateView(for: state)
                }
                .store(in: &bag)

            $selectedAction
                .dropFirst()
                .sink { [weak self] action in
                    self?.swappingInteractor.update(approvePolicy: action)
                }
                .store(in: &bag)
        }
    }

    func updateFeeAmount(for transactionData: SwappingTransactionData) {
        runTask(in: self) { root in
            do {
                let fee = transactionData.fee
                let fiatFee = try await root.fiatRatesProvider.getFiat(for: transactionData.sourceBlockchain, amount: fee)

                await runOnMain {
                    root.updateFeeRowViewModel(fee: fee, fiatFee: fiatFee)
                }
            } catch {
                AppLog.shared.error(error)

                await runOnMain {
                    root.updateFeeRowViewModel(fee: 0, fiatFee: 0)
                }
            }
        }
    }

    func updateView(for state: SwappingAvailabilityState) {
        switch state {
        case .idle, .preview:
            updateFeeRowViewModel(fee: 0, fiatFee: 0)
            isLoading = false
            mainButtonIsDisabled = true
        case .loading:
            feeRowViewModel?.update(detailsType: .loader)
            isLoading = true
            mainButtonIsDisabled = false
        case .available(let model):
            updateFeeAmount(for: model.transactionData)
            isLoading = false
            mainButtonIsDisabled = false
        case .requiredRefresh(let error):
            errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
            isLoading = false
            mainButtonIsDisabled = true
        }
    }

    func updateFeeRowViewModel(fee: Decimal, fiatFee: Decimal) {
        let fiatFeeFormatted = format(fee: fee, fiatFee: fiatFee)
        feeRowViewModel?.update(detailsType: .text(fiatFeeFormatted))
    }

    func setupView() {
        guard let transactionData = transactionData else {
            AppLog.shared.debug("TransactionData for approve isn't found")
            return
        }

        let tokenSymbol = swappingInteractor.getSwappingItems().source.symbol
        menuRowViewModel = .init(
            title: Localization.swappingPermissionRowsAmount(tokenSymbol),
            actions: [
                SwappingApprovePolicy.unlimited,
                SwappingApprovePolicy.specified,
            ]
        )

        let fee = transactionData.fee
        let sourceBlockchain = transactionData.sourceBlockchain

        if let fiatFee = fiatRatesProvider.getFiat(for: sourceBlockchain, amount: fee) {
            let fiatFeeFormatted = format(fee: fee, fiatFee: fiatFee)
            feeRowViewModel = DefaultRowViewModel(
                title: Localization.sendFeeLabel,
                detailsType: .text(fiatFeeFormatted)
            )
        } else {
            // If we don't have the rates then load it asynchronously
            feeRowViewModel = DefaultRowViewModel(
                title: Localization.sendFeeLabel,
                detailsType: .loader
            )

            updateFeeAmount(for: transactionData)
        }
    }

    func format(fee: Decimal, fiatFee: Decimal) -> String {
        let feeFormatted = fee.groupedFormatted()
        let fiatFeeFormatted = fiatFee.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
        let tokenSymbol = swappingInteractor.getSwappingItems().source.blockchain.symbol

        return "\(feeFormatted) \(tokenSymbol) (\(fiatFeeFormatted))"
    }
}

// MARK: - Express

private extension SwappingApproveViewModel {
    func updateView(for state: ExpressInteractor.ExpressInteractorState) {
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
            updateFeeRowViewModel(fee: 0, fiatFee: 0)
            isLoading = false
            mainButtonIsDisabled = true
        }
    }

    func updateFeeAmount(fees: [FeeOption: Fee]) {
        let blockchain = expressInteractor.getSender().tokenItem.blockchain

        guard let fee = fees[expressInteractor.getFeeOption()] else {
            errorAlert = AlertBinder(
                title: Localization.commonError,
                message: ExpressInteractorError.feeNotFound.localizedDescription
            )

            return
        }

        let formatted = swappingFeeFormatter.format(
            fee: fee.amount.value,
            currencySymbol: blockchain.currencySymbol,
            currencyId: blockchain.currencyId
        )
        feeRowViewModel?.update(detailsType: .text(formatted))
    }

    func setupExpressView() {
        let currencySymbol = expressInteractor.getSender().tokenItem.currencySymbol
        menuRowViewModel = .init(
            title: Localization.swappingPermissionRowsAmount(currencySymbol),
            actions: [
                SwappingApprovePolicy.unlimited,
                SwappingApprovePolicy.specified,
            ]
        )

        feeRowViewModel = DefaultRowViewModel(title: Localization.sendFeeLabel, detailsType: .none)
        updateView(for: expressInteractor.getState())
    }

    func sendApproveTransaction() {
        runTask(in: self) { viewModel in
            do {
                try await viewModel.expressInteractor.sendApproveTransaction()
                await viewModel.didSendApproveTransaction()
            } catch TangemSdkError.userCancelled {
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

extension SwappingApprovePolicy: DefaultMenuRowViewModelAction {
    public var id: Int { hashValue }

    public var title: String {
        switch self {
        case .specified:
            return Localization.swappingPermissionCurrentTransaction
        case .unlimited:
            return Localization.swappingPermissionUnlimited
        }
    }
}
