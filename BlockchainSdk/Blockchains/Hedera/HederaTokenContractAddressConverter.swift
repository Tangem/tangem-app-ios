//
//  HederaTokenContractAddressConverter.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 14.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import struct Hedera.AccountId

public struct HederaTokenContractAddressConverter {
    public func convertFromEVMToHedera(_ evmAddress: String) throws -> String {
        return try AccountId
            .fromSolidityAddress(evmAddress.addHexPrefix()) // adding the '0x' prefix just for consistency
            .toString()
    }

    public func convertFromHederaToEVM(_ hederaAddress: String) throws -> String {
        return try AccountId
            .fromString(hederaAddress)
            .toSolidityAddress()
            .addHexPrefix()
    }

    public init() {}
}
