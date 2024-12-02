//
//  BitcoinCashAddressPrefixProvider.swift
//  TangemApp
//
//  Created by Dmitry Fedorov on 02.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct BitcoinCashAddressPrefixProvider {
    private let prefix = "bitcoincash:"
    let addressService: BitcoinCashAddressService
}

extension BitcoinCashAddressPrefixProvider: AddressPrefixProvider {
    func addPrefixIfNeeded(_ address: String) -> String {
        if addressService.isLegacy(address) {
            return address
        } else {
            return address.hasPrefix(prefix) ? address : prefix + address
        }
    }
}
