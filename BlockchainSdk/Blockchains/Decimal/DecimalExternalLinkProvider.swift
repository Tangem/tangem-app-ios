//
//  DecimalExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct DecimalExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }

    private let isTestnet: Bool

    private var baseExplorerUrl: String {
        if isTestnet {
            return "https://testnet.explorer.decimalchain.com"
        } else {
            return "https://explorer.decimalchain.com"
        }
    }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func url(address: String, contractAddress: String?) -> URL? {
        let convertedAddress = (try? DecimalAddressConverter().convertToETHAddress(address)) ?? address
        return URL(string: "\(baseExplorerUrl)/address/\(convertedAddress)")
    }

    func url(transaction hash: String) -> URL? {
        /*
         - Now it’s nil because decimal scanner explorer can’t read our hash of the transaction that the evm service makes

         */
        return nil
    }
}
