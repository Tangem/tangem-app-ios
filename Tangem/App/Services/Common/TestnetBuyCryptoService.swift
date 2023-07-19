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
        case .erc20Token(let token, let walletModel, let signer):
            buyErc20Token(token, walletModel: walletModel, signer: signer)
        }
    }

    private func buyErc20Token(_ token: Token, walletModel: WalletModel, signer: TangemSigner) {
        let amountToSend = Amount(with: walletModel.wallet.blockchain, value: 0)
        let destinationAddress = token.contractAddress

        var subs: AnyCancellable!

        subs = walletModel.getFee(amount: amountToSend, destination: destinationAddress)
            .flatMap { fees -> AnyPublisher<Void, Error> in
                guard let fee = fees.first,
                      fee.amount.value <= walletModel.wallet.amounts[.coin]?.value ?? 0 else {
                    return .anyFail(error: "Not enough funds on ETH wallet balance. You need to topup ETH wallet first")
                }

                guard let tx = try? walletModel.createTransaction(amountToSend: amountToSend, fee: fee, destinationAddress: destinationAddress) else {
                    return .anyFail(error: "Failed to create topup transaction for token. Try again later")
                }

                return walletModel.send(tx, signer: signer)
            }
            .sink { [unowned self] completion in
                if case .failure(let error) = completion {
                    AppLog.shared.error(error)
                    AppPresenter.shared.showError(error)
                } else {
                    AppPresenter.shared.show(AlertBuilder.makeSuccessAlertController(message: "Transaction signed and sent to testnet. Wait for a while and reload balance"))
                }

                bag.remove(subs)
                subs = nil
            } receiveValue: { _ in }

        bag.insert(subs)
    }
}

extension TestnetBuyCryptoService {
    enum CryptoToBuy {
        case erc20Token(_ token: Token, walletModel: WalletModel, signer: TangemSigner)
    }
}
