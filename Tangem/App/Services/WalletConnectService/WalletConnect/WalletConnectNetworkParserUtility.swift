//
//  WalletConnectNetworkParserUtility.swift
//  Tangem
//
//  Created by Andrew Son on 26/07/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import BlockchainSdk

enum WalletConnectNetworkParserUtility {
    struct ParseResult {
        let network: WalletConnectNetwork
        let chainId: Int
    }

    static func parse(dAppInfo: Session.DAppInfo, testnet: Bool) -> ParseResult? {
        let wcNetwork: WalletConnectNetwork
        var chainId: Int = -1
        if let id = dAppInfo.chainId {
            chainId = id
            wcNetwork = .eth(chainId: id)

            // There is no adequate way to determine which network we are trying to connect to and create a WC session,
            // icon links are the only thing that is different and allows us to determine whether we are connecting to testnet or mainnet.
            // But this only applies to binance.org and suddenly for wallet.matic.network.
            // So far, I could not find alternative services where you can connect Binance wallet via WC.
            // peer_id is never the same for the dApp
            // I think this list will continue to expand
        } else if dAppInfo.peerMeta.url.absoluteString.contains("polygon.technology") {
            let id = Blockchain.polygon(testnet: false).chainId!
            wcNetwork = .eth(chainId: id)
            chainId = id
        } else if dAppInfo.peerMeta.url.absoluteString.hasSuffix("binance.org") {
            if dAppInfo.peerMeta.icons.first?.absoluteString.contains("dex-bin") ?? false {
                wcNetwork = .bnb(testnet: false)
            } else if !dAppInfo.peerMeta.icons.filter({ $0.absoluteString.contains("testnet-bin") }).isEmpty {
                wcNetwork = .bnb(testnet: true)
            } else {
                return nil
            }
        } else {
            // WC interface doesn't provide info about network. So in cases when chainId is null we use ethereum main network
            // Dapps on ethereum mainnet sending null in chainId
            let id = Blockchain.ethereum(testnet: testnet).chainId!
            chainId = id
            wcNetwork = .eth(chainId: id)
        }
        return .init(network: wcNetwork, chainId: chainId)
    }
}
