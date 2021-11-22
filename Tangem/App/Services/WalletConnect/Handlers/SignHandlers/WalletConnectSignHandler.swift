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
    
    let signer: TangemSigner
    
    private var signerSubscription: AnyCancellable?
    
    init(signer: TangemSigner, delegate: WalletConnectHandlerDelegate, dataSource: WalletConnectHandlerDataSource) {
        self.signer = signer
        self.delegate = delegate
        self.dataSource = dataSource
    }
    
    func handle(request: Request) { }
    
    func signatureResponse(for signature: String, session: WalletConnectSession, request: Request) -> Response {
        fatalError("Must be overriden by a subclass")
    }
    
    func sign(data: Data, cardId: String, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<String, Error> {
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
        
        let alertMessage =  String(format: "wallet_connect_alert_sign_message".localized, AppCardIdFormatter(cid: session.wallet.cid).formatted(), message)
        DispatchQueue.main.async {
            UIApplication.modalFromTop(
                WalletConnectUIBuilder.makeAlert(for: .sign,
                                                 message: alertMessage,
                                                 onAcceptAction: onSign,
                                                 onReject: { self.delegate?.sendReject(for: request,
                                                                                       with: WalletConnectServiceError.cancelled,
                                                                                       for: self.action) })
            )
        }
    }
    
    func sign(with wallet: WalletInfo, data: Data, completion: @escaping (Result<String, Error>) -> Void) {
        signerSubscription = sign(data: data,
                                  cardId: wallet.cid,
                                  walletPublicKey: wallet.walletPublicKey)
            .sink(receiveCompletion: { [weak self] subsCompletion in
                if case let .failure(error) = subsCompletion {
                    completion(.failure(error))
                }
                self?.signerSubscription = nil
            }, receiveValue: { signature in
                completion(.success(signature))
            })
    }
}
