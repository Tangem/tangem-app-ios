//
//  SendAddressServiceFactory.swift
//  Tangem
//
//  Created by Andrey Chukavin on 21.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendAddressServiceFactory {
    private let walletModel: WalletModel

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }

    func makeService() -> SendAddressService {
        let addressService = AddressServiceFactory(blockchain: walletModel.wallet.blockchain).makeAddressService()
        let defaultSendAddressService = DefaultSendAddressService(
            walletAddresses: walletModel.wallet.addresses,
            addressService: addressService,
            supportSameAsWalletAddressTransfer: walletModel.wallet.blockchain.supportSameAsWalletAddressTransfer
        )

        if let addressResolver = walletModel.addressResolver {
            return SendResolvableAddressService(defaultSendAddressService: defaultSendAddressService, addressResolver: addressResolver)
        } else {
            return defaultSendAddressService
        }
    }
}

private extension Blockchain {
    var supportSameAsWalletAddressTransfer: Bool {
        switch self {
        case .bitcoin,
             .bitcoinCash,
             .litecoin,
             .dogecoin,
             .dash,
             .kaspa:
            return true
        default:
            return false
        }
    }
}
