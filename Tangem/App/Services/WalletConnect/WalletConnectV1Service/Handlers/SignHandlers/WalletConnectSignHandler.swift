//
//  WalletConnectSignHandler.swift
//  Tangem
//
//  Created by Andrew Son on 14/04/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import TangemSdk
import BlockchainSdk
import Combine

class WalletConnectSignHandler: TangemWalletConnectRequestHandler {
    weak var delegate: WalletConnectHandlerDelegate?
    weak var dataSource: WalletConnectHandlerDataSource?

    var action: WalletConnectAction {
        fatalError("WalletConnect action not specified")
    }

    private var signerSubscription: AnyCancellable?

    init(delegate: WalletConnectHandlerDelegate, dataSource: WalletConnectHandlerDataSource) {
        self.delegate = delegate
        self.dataSource = dataSource
    }

    func handle(request: Request) {}

    func signatureResponse(for signature: String, session: WalletConnectSession, request: Request) -> Response {
        fatalError("Must be overriden by a subclass")
    }

    func sign(data: Data, walletPublicKey: Wallet.PublicKey, signer: TangemSigner) -> AnyPublisher<String, Error> {
        fatalError("Must be overriden by a subclass")
    }

    func askToSign(in session: WalletConnectSession, request: Request, message: String, dataToSign: Data) {
        let wallet = session.wallet

        let onSign: () -> Void = { [weak self] in
            self?.sign(with: wallet, data: dataToSign) { res in
                DispatchQueue.global().async {
                    guard let self = self else { return }

                    switch res {
                    case .success(let signature):
                        self.delegate?.send(self.signatureResponse(for: signature, session: session, request: request), for: self.action)
                    case .failure(let error):
                        self.delegate?.sendReject(for: request, with: error, for: self.action)
                    }
                }
            }
        }

        let alertMessage = Localization.walletConnectAlertSignMessage(message)
        let controller = WalletConnectUIBuilder.makeAlert(
            for: .sign,
            message: alertMessage,
            onAcceptAction: onSign,
            onReject: { self.delegate?.sendReject(
                for: request,
                with: WalletConnectServiceError.cancelled,
                for: self.action
            ) }
        )
        AppPresenter.shared.show(controller)
    }

    func sign(with wallet: WalletInfo, data: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cardModel = dataSource?.cardModel else {
            completion(.failure(WalletConnectServiceError.deallocated))
            return
        }

        let targetNetwork = BlockchainNetwork(wallet.blockchain, derivationPath: wallet.derivationPath)
        guard let cardWallet = cardModel.walletModels.first(where: { $0.blockchainNetwork == targetNetwork })?.wallet else {
            completion(.failure(WalletConnectServiceError.signFailed))
            return
        }

        signerSubscription = sign(
            data: data,
            walletPublicKey: cardWallet.publicKey,
            signer: cardModel.signer
        )
        .sink(receiveCompletion: { [weak self] subsCompletion in
            if case .failure(let error) = subsCompletion {
                completion(.failure(error))
            }
            self?.signerSubscription = nil
        }, receiveValue: { signature in

            completion(.success(signature))
        })
    }
}
