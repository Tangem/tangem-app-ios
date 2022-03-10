//
//  SignTypedDataHandler.swift
//  Tangem
//
//  Created by Alexander Osokin on 21.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//
/// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md

import Foundation
import WalletConnectSwift
import Combine
import TangemSdk
import BlockchainSdk

class SignTypedDataHandler: WalletConnectSignHandler {
    
    override var action: WalletConnectAction { .signTypedData }

    override func handle(request: Request) {
        do {
            let message = try request.parameter(of: String.self, at: 1)
            let address = try request.parameter(of: String.self, at: 0)

            guard let session = dataSource?.session(for: request, address: address),
                  let messageData = message.data(using: .utf8),
                  let typedData = try? JSONDecoder().decode(EIP712TypedData.self, from: messageData) else {
                      delegate?.send(.reject(request), for: action)
                      return
                  }
        
            let prefix = String(format: "wallet_connect_personal_sign_message".localized, session.session.dAppInfo.peerMeta.name)
            askToSign(in: session, request: request, message: prefix + message, dataToSign: typedData.signHash)
        } catch {
            delegate?.sendInvalid(request)
        }
    }
    
    override func signatureResponse(for signature: String, session: WalletConnectSession, request: Request) -> Response {
        .signature(signature, for: request)
    }
    
    override func sign(data: Data, cardId: String, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<String, Error> {
        return signer.sign(hash: data, cardId: cardId, walletPublicKey: walletPublicKey)
            .tryMap { response -> String in
                if let unmarshalledSig = try? Secp256k1Signature(with: response).unmarshal(with: walletPublicKey.blockchainKey,
                                                                                           hash: data) {
                    let strSig =  "0x" + unmarshalledSig.r.hexString + unmarshalledSig.s.hexString +
                    unmarshalledSig.v.hexString
                    
                    return strSig
                } else {
                    throw WalletConnectServiceError.signFailed
                }
            }
            .eraseToAnyPublisher()
    }
}
