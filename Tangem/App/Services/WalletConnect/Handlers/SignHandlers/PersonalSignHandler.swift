//
//  PersonalSignHandler.swift
//  Tangem
//
//  Created by Alexander Osokin on 02.04.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import Combine
import TangemSdk
import BlockchainSdk

class PersonalSignHandler: WalletConnectSignHandler {
    
    override var action: WalletConnectAction { .personalSign }

    override func handle(request: Request) {
        do {
            let messageBytes = try request.parameter(of: String.self, at: 0)
            let address = try request.parameter(of: String.self, at: 1)

            guard let session = dataSource?.session(for: request, address: address) else {
                delegate?.send(.reject(request), for: action)
                return
            }
        
            let messageData = Data(hex: messageBytes)
            let prefix = String(format: "wallet_connect_personal_sign_message".localized, session.session.dAppInfo.peerMeta.name)
            let personalMessageData = self.makePersonalMessageData(messageData)
            
            askToSign(in: session, request: request, message: prefix + messageBytes, dataToSign: personalMessageData)
        } catch {
            delegate?.sendInvalid(request)
        }
    }
    
    override func signatureResponse(for signature: String, session: WalletConnectSession, request: Request) -> Response {
        .signature(signature, for: request)
    }
    
    override func sign(data: Data, cardId: String, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<String, Error> {
        let hash = data.sha3(.keccak256)
        
        return signer.sign(hash: hash, cardId: cardId, walletPublicKey: walletPublicKey)
            .tryMap { response -> String in
                if let unmarshalledSig = try? Secp256k1Signature(with: response).unmarshal(with: walletPublicKey.blockchainKey,
                                                                                           hash: hash) {
                    let strSig =  "0x" + unmarshalledSig.r.hexString + unmarshalledSig.s.hexString +
                    unmarshalledSig.v.hexString
                    return strSig
                } else {
                    throw WalletConnectServiceError.signFailed
                }
            }
            .eraseToAnyPublisher()
    }

    private func makePersonalMessageData(_ data: Data) -> Data {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let prefixData = (prefix + "\(data.count)").data(using: .utf8)!
        return prefixData + data
    }
    
}

