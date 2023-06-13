//
//  TestnetTopupService.swift
//  Tangem
//
//  Created by Andrew Son on 10/06/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import UIKit

class TestnetBuyCryptoService {
    private var bag: Set<AnyCancellable> = []

    func buyCrypto(_ target: CryptoToBuy) {
        switch target {
        case .erc20Token(let token, let walletManager, let signer):
            buyErc20Token(token, walletManager: walletManager, signer: signer)
        }
    }

    private func buyErc20Token(_ token: Token, walletManager: WalletManager, signer: TransactionSigner) {
        let amountToSend = Amount(with: walletManager.wallet.blockchain, value: 0)
        let destinationAddress = token.contractAddress

        var subs: AnyCancellable!
        subs = walletManager.getFee(amount: amountToSend, destination: destinationAddress)
            .flatMap { fees -> AnyPublisher<TransactionSendResult, Error> in
                guard let fee = fees.first,
                      fee.amount.value <= walletManager.wallet.amounts[.coin]?.value ?? 0 else {
                    return .anyFail(error: Localization.testnetErrorNotEnoughEtherMessage)
                }

                guard let tx = try? walletManager.createTransaction(amount: amountToSend, fee: fee, destinationAddress: destinationAddress) else {
                    return .anyFail(error: Localization.testnetErrorFailedCreateTx)
                }

                return walletManager.send(tx, signer: signer)
            }
            .sink { [unowned self] completion in
                if case .failure(let error) = completion {
                    AppLog.shared.error(error)
                    AppPresenter.shared.showError(error)
                } else {
                    AppPresenter.shared.show(AlertBuilder.makeSuccessAlertController(message: Localization.testnetAddressTopuped))
                }

                bag.remove(subs)
                subs = nil
            } receiveValue: { _ in }

        bag.insert(subs)
    }
}

extension TestnetBuyCryptoService {
    enum CryptoToBuy {
        case erc20Token(_ token: Token, walletManager: WalletManager, signer: TransactionSigner)
    }
}
