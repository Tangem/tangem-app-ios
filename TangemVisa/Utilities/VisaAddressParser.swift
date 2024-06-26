//
//  VisaAddressParser.swift
//  TangemVisa
//
//  Created by Andrew Son on 18/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct AddressParser {
    private let addressLength = 42
    private let prefixLength = "0x".count

    private var addressService: AddressService

    init(isTestnet: Bool) {
        let blockchain = VisaUtilities(isTestnet: isTestnet).visaBlockchain
        addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
    }

    func parseAddressResponse(_ response: String) throws -> String {
        guard
            response.hasHexPrefix(),
            response.count >= addressLength
        else {
            throw VisaParserError.addressResponseDoesntContainAddress
        }

        var parsedAddress = response
        if parsedAddress.count > addressLength {
            parsedAddress = String(parsedAddress.suffix(addressLength - prefixLength)).addHexPrefix()
        }

        guard addressService.validate(parsedAddress) else {
            throw VisaParserError.noValidAddress
        }

        return parsedAddress
    }
}
