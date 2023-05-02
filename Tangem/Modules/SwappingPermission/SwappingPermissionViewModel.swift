//
//  SwappingPermissionViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemSwapping
import TangemSdk

final class SwappingPermissionViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var contentRowViewModels: [DefaultRowViewModel] = []
    @Published var errorAlert: AlertBinder?

    var tokenSymbol: String {
        inputModel.transactionData.sourceCurrency.symbol
    }

    // MARK: - Dependencies

    private let inputModel: SwappingPermissionInputModel
    private let transactionSender: SwappingTransactionSender
    private unowned let coordinator: SwappingPermissionRoutable

    private var didBecomeActiveNotificationCancellable: AnyCancellable?

    init(
        inputModel: SwappingPermissionInputModel,
        transactionSender: SwappingTransactionSender,
        coordinator: SwappingPermissionRoutable
    ) {
        self.inputModel = inputModel
        self.transactionSender = transactionSender
        self.coordinator = coordinator

        setupView()
    }

    func didTapInfoButton() {
        errorAlert = AlertBinder(
            title: Localization.swappingApproveInformationTitle,
            message: Localization.swappingApproveInformationText
        )
    }

    func didTapApprove() {
        let data = inputModel.transactionData

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

extension SwappingPermissionViewModel {
    @MainActor
    func didSendApproveTransaction(transactionData: SwappingTransactionData) {
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

private extension SwappingPermissionViewModel {
    func setupView() {
        let transactionData = inputModel.transactionData
        /// Addresses have to the same width for both
        let walletAddress = AddressFormatter(address: transactionData.sourceAddress).truncated()
        let spenderAddress = AddressFormatter(address: transactionData.destinationAddress).truncated()

        let fiatFee = inputModel.fiatFee.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
        let formattedFee = transactionData.fee.groupedFormatted()
        let feeLabel = "\(formattedFee) \(inputModel.transactionData.sourceBlockchain.symbol) (\(fiatFee))"

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
