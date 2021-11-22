//
//  WalletConnectModels.swift
//  Tangem
//
//  Created by Andrew Son on 10/04/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import WalletConnectSwift
import TangemSdk

struct WalletInfo: Codable, Hashable {
    let cid: String
    let walletPublicKey: Wallet.PublicKey
    let blockchain: Blockchain
    let chainId: Int?
    
    var address: String {
        blockchain.makeAddresses(from: walletPublicKey.blockchainKey, with: nil).first!.value
    }
    
    internal init(cid: String, walletPublicKey: Wallet.PublicKey, blockchain: Blockchain, chainId: Int?) {
        self.cid = cid
        self.walletPublicKey = walletPublicKey
        self.blockchain = blockchain
        self.chainId = chainId
    }
}

struct WalletConnectSession: Codable, Hashable, Identifiable {
    var id: String { session.dAppInfo.peerId + "\(wallet.hashValue)" }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(wallet.hashValue)
        hasher.combine(session.dAppInfo.peerId)
    }
    
    let wallet: WalletInfo
    var session: Session
    var status: SessionStatus = .disconnected
    
    private enum CodingKeys: String, CodingKey {
        case wallet, session
    }
}

enum SessionStatus: Int, Codable {
    case disconnected
    case connecting
    case connected
}

extension Session: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.dAppInfo == rhs.dAppInfo && lhs.walletInfo == rhs.walletInfo
    }
}

extension Response {
    static func signature(_ signature: String, for request: Request) -> Response {
        return try! Response(url: request.url, value: signature, id: request.id!)
    }
}
