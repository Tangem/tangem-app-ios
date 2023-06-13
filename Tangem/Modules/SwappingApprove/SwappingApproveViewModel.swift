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

final class SwappingApproveViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var menuRowViewModel: DefaultMenuRowViewModel<SwappingApprovePolicy>?
    @Published var selectedAction: SwappingApprovePolicy
    @Published var feeRowViewModel: DefaultRowViewModel?

    @Published var isLoading = false
    @Published var mainButtonIsDisabled = false
    @Published var errorAlert: AlertBinder?

    var tokenSymbol: String {
        swappingInteractor.getSwappingItems().source.symbol
    }

    // MARK: - Dependencies

    private let transactionSender: SwappingTransactionSender
    private let swappingInteractor: SwappingInteractor
    private let fiatRatesProvider: FiatRatesProviding
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
        transactionSender: SwappingTransactionSender,
        swappingInteractor: SwappingInteractor,
        fiatRatesProvider: FiatRatesProviding,
        coordinator: SwappingApproveRoutable
    ) {
        self.transactionSender = transactionSender
        self.swappingInteractor = swappingInteractor
        self.fiatRatesProvider = fiatRatesProvider
        self.coordinator = coordinator

        self.selectedAction = swappingInteractor.getSwappingApprovePolicy()
        setupView()
        bind()
    }

    func didTapInfoButton() {
        errorAlert = AlertBinder(
            title: Localization.swappingApproveInformationTitle,
            message: Localization.swappingApproveInformationText
        )
    }

    func didTapApprove() {
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

        Task {
            do {
                _ = try await transactionSender.sendTransaction(data)
                await didSendApproveTransaction(transactionData: data)
            } catch TangemSdkError.userCancelled {
                // Do nothing
            } catch {
                await runOnMain {
                    errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
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
    func didSendApproveTransaction(transactionData: SwappingTransactionData) {
        swappingInteractor.didSendApproveTransaction(swappingTxData: transactionData)

        // We have to waiting close the nfc view to close this permission view
        didBecomeActiveNotificationCancellable = NotificationCenter
            .default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.coordinator.didSendApproveTransaction(transactionData: transactionData)
            }
    }
}

// MARK: - Private

private extension SwappingApproveViewModel {
    func bind() {
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

    func updateFeeAmount(for transactionData: SwappingTransactionData) {
        Task {
            do {
                let fee = transactionData.fee
                let fiatFee = try await fiatRatesProvider.getFiat(for: transactionData.sourceBlockchain, amount: fee)

                await runOnMain {
                    updateFeeRowViewModel(fee: fee, fiatFee: fiatFee)
                }
            } catch {
                AppLog.shared.error(error)

                await runOnMain {
                    updateFeeRowViewModel(fee: 0, fiatFee: 0)
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

        menuRowViewModel = .init(
            title: Localization.swappingPermissionRowsAmount(tokenSymbol),
            actions: [
                SwappingApprovePolicy.unlimited,
                SwappingApprovePolicy.amount(transactionData.sourceAmount),
            ]
        )

        let fee = transactionData.fee
        let sourceBlockchain = transactionData.sourceBlockchain

        if fiatRatesProvider.hasRates(for: sourceBlockchain),
           let fiatFee = fiatRatesProvider.getSyncFiat(for: sourceBlockchain, amount: fee) {
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

extension SwappingApprovePolicy: DefaultMenuRowViewModelAction {
    public var id: Int { hashValue }

    public var title: String {
        switch self {
        case .amount:
            return Localization.swappingPermissionCurrentTransaction
        case .unlimited:
            return Localization.swappingPermissionUnlimited
        }
    }
}
