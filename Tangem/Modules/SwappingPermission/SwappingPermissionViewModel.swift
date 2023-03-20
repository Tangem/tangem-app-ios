//
//  SwappingPermissionViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemExchange
import TangemSdk

final class SwappingPermissionViewModel: ObservableObject, Identifiable {
    /// For SwiftUI sheet logic
    let id: UUID = .init()

    // MARK: - ViewState

    @Published var contentRowViewModels: [DefaultRowViewModel] = []
    @Published var errorAlert: AlertBinder?

    var tokenSymbol: String {
        inputModel.transactionInfo.sourceCurrency.symbol
    }

    // MARK: - Dependencies

    private let inputModel: SwappingPermissionInputModel
    private let transactionSender: TransactionSendable
    private unowned let coordinator: SwappingPermissionRoutable

    private var didBecomeActiveNotificationCancellable: AnyCancellable?

    init(
        inputModel: SwappingPermissionInputModel,
        transactionSender: TransactionSendable,
        coordinator: SwappingPermissionRoutable
    ) {
        self.inputModel = inputModel
        self.transactionSender = transactionSender
        self.coordinator = coordinator

        setupView()
    }

    func didTapApprove() {
        let info = inputModel.transactionInfo

        Analytics.log(
            event: .swapButtonPermissionApprove,
            params: [
                .sendToken: info.sourceCurrency.symbol,
                .receiveToken: info.destinationCurrency.symbol,
            ]
        )

        Task {
            do {
                _ = try await transactionSender.sendTransaction(info)
                await didSendApproveTransaction(transactionInfo: info)
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

extension SwappingPermissionViewModel {
    @MainActor
    func didSendApproveTransaction(transactionInfo: ExchangeTransactionDataModel) {
        // We have to waiting close the nfc view to close this permission view
        didBecomeActiveNotificationCancellable = NotificationCenter
            .default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.coordinator.didSendApproveTransaction(transactionInfo: transactionInfo)
            }
    }
}

// MARK: - Private

private extension SwappingPermissionViewModel {
    func setupView() {
        let transactionInfo = inputModel.transactionInfo
        /// Addresses have to the same width for both
        let walletAddress = AddressFormatter(address: transactionInfo.sourceAddress).truncated()
        let spenderAddress = AddressFormatter(address: transactionInfo.destinationAddress).truncated()

        let fiatFee = inputModel.fiatFee.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
        let formattedFee = transactionInfo.fee.groupedFormatted()
        let feeLabel = "\(formattedFee) \(inputModel.transactionInfo.sourceBlockchain.symbol) (\(fiatFee))"

        contentRowViewModels = [
            DefaultRowViewModel(
                title: Localization.swappingPermissionRowsYourWallet,
                detailsType: .text(String(walletAddress))
            ),
            DefaultRowViewModel(
                title: Localization.swappingPermissionRowsSpender,
                detailsType: .text(String(spenderAddress))
            ),
            DefaultRowViewModel(
                title: Localization.sendFeeLabel,
                detailsType: .text(feeLabel)
            ),
        ]
    }
}
